codeunit 137082 "SCM Manufacturing - Routings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Production] [Routing]
    end;

    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotLinearCCErr: Label 'Computational cost is not linear.';
        CircularReferenceErr: Label 'Circular reference in routing %1', Comment = '%1 = Routing No.';
        WrongNoOfTerminationProcessesErr: Label 'Actual number of termination processes in route %1 is %2', Comment = '%1 = Routing No., %2 = No. of operations';
        WrongNoOfStartProcessesErr: Label 'Actual number of start processes in route %1 is %2', Comment = '%1 = Routing No., %2 = No. of operations';
        NoLineWithinFilterErr: Label 'There is no Routing Line within the filter';
        isInitialized: Boolean;
        CannotDeleteCertifiedRoutingExistsErr: Label 'You cannot delete %1 %2 because there is at least one certified %3 associated with it.';

    [Test]
    [Scope('OnPrem')]
    procedure SimpleSerialRouting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Serial Routing]
        // [SCENARIO 221561] Certification of a serial routing should update sequence numbers on routing operations

        Initialize;

        // [GIVEN] Create a serial routing with 3 operations
        // [GIVEN] 1 -> 2 -> 3
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The field "Sequence No. (Forward)" in operations has numbers from 1 to 3
        // [THEN] The field "Sequence No. (Backeward)" in operations has numbers from 3 to 1
        for I := 1 to ArrayLen(RoutingLine) do begin
            RoutingLine[I].Find;
            RoutingLine[I].TestField("Sequence No. (Forward)", I);
            RoutingLine[I].TestField("Sequence No. (Backward)", ArrayLen(RoutingLine) - I + 1);
        end;

        // [THEN] "Previous Operation No." is blank in the starting operation
        // [THEN] "Next Operation No." is blank in the terminal operation
        RoutingLine[1].TestField("Next Operation No.", RoutingLine[2]."Operation No.");
        RoutingLine[1].TestField("Previous Operation No.", '');

        RoutingLine[2].TestField("Next Operation No.", RoutingLine[3]."Operation No.");
        RoutingLine[2].TestField("Previous Operation No.", RoutingLine[1]."Operation No.");

        RoutingLine[3].TestField("Next Operation No.", '');
        RoutingLine[3].TestField("Previous Operation No.", RoutingLine[2]."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleParallelRouting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should update sequence numbers on routing operations

        Initialize;

        // [GIVEN] Create a parallel routing with 3 operations
        // [GIVEN] 1 -> 2 -> 3
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup sequential execuion of the operations by filling the "Next Operation No." field
        SetNextOperationNo(RoutingLine[1], RoutingLine[2]."Operation No.");
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The field "Sequence No. (Forward)" in operations has numbers from 1 to 3
        // [THEN] The field "Sequence No. (Backeward)" in operations has numbers from 3 to 1
        for I := 1 to ArrayLen(RoutingLine) do begin
            RoutingLine[I].Find;
            RoutingLine[I].TestField("Sequence No. (Forward)", I);
            RoutingLine[I].TestField("Sequence No. (Backward)", ArrayLen(RoutingLine) - I + 1);
        end;

        // [THEN] "Previous Operation No." is blank in the starting operation
        // [THEN] "Next Operation No." is blank in the terminal operation
        RoutingLine[1].TestField("Previous Operation No.", '');
        RoutingLine[2].TestField("Previous Operation No.", RoutingLine[1]."Operation No.");
        RoutingLine[3].TestField("Previous Operation No.", RoutingLine[2]."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyRoutingTwoParallelOperations()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[4] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Two parallel operations should receive the same sequence no. on certifying a routing

        Initialize;

        // [GIVEN] Create a parallel routing with 4 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 3 are executed in parallel, terminal operation 4
        // [GIVEN]   1
        // [GIVEN]  / \
        // [GIVEN] 2   3
        // [GIVEN]  \ /
        // [GIVEN]   4
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] "Sequence No. (Forward)" in operation 1 is "1", "Sequence No. (Backward)" is "3"
        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 3
        // [THEN]                           / \                                    / \
        // [THEN]                          2   2                                  2   2
        // [THEN]                           \ /                                    \ /
        // [THEN]                            3                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[1].TestField("Sequence No. (Backward)", 3);

        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[2].TestField("Sequence No. (Backward)", 2);

        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 2);

        RoutingLine[4].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Backward)", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingImbalancedExecutionTree()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[5] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Verify sequence numbers on two parallel executions paths having different number of operations

        Initialize;

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 3 are executed in parallel
        // [GIVEN] Operation 4 is executed sequentially after op. 3, both 2 and 4 lead to the terminal operation 5
        // [GIVEN]    1
        // [GIVEN]   / \
        // [GIVEN]  2   3
        // [GIVEN]  |   |
        // [GIVEN]  |   4
        // [GIVEN]   \ /
        // [GIVEN]    5
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[5]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[5]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 4
        // [THEN]                           / \                                    / \
        // [THEN]                          2   2                                  2   3
        // [THEN]                          |   |                                  |   |
        // [THEN]                          |   3                                  |   2
        // [THEN]                           \ /                                    \ /
        // [THEN]                            4                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[1].TestField("Sequence No. (Backward)", 4);

        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[2].TestField("Sequence No. (Backward)", 2);

        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);

        RoutingLine[4].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);

        RoutingLine[5].TestField("Sequence No. (Forward)", 4);
        RoutingLine[5].TestField("Sequence No. (Backward)", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingLongWayPointsToShortWay()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Array[5] of Record "Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 340158] Sequence numbers on two parallel execution paths of different lengths, long way points to short way.
        Initialize;

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 5 are executed in parallel.
        // [GIVEN] Way A: 1 → 2 → 3 → 4 → 5; Way B: 1 → 5. Termination operation 5.
        // [GIVEN]   1
        // [GIVEN]  / \ 
        // [GIVEN] 5   2
        // [GIVEN] ↑   ↓
        // [GIVEN]  \  3
        // [GIVEN]   \ ↓
        // [GIVEN]     4
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[5]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 5
        // [THEN]                           / \                                    / \
        // [THEN]                          5   2                                  1   4
        // [THEN]                          |   |                                  |   |
        // [THEN]                           \  3                                   \  3
        // [THEN]                            \ |                                    \ |
        // [THEN]                              4                                      2
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Forward)", 4);
        RoutingLine[5].TestField("Sequence No. (Forward)", 5);

        RoutingLine[5].TestField("Sequence No. (Backward)", 1);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);
        RoutingLine[2].TestField("Sequence No. (Backward)", 4);
        RoutingLine[1].TestField("Sequence No. (Backward)", 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingShortWayPointsToLongWay()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Array[5] of Record "Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 340158] Sequence numbers on two parallel execution paths of different lengths, short way points to long way.
        Initialize;

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 3 are executed in parallel.
        // [GIVEN] Way A: 1 → 2; Way B: 1 → 3 → 4 → 5. Termination operation 5.
        // [GIVEN]   1
        // [GIVEN]  / \ 
        // [GIVEN] 2 → 3
        // [GIVEN]     ↓
        // [GIVEN]     4
        // [GIVEN]     ↓
        // [GIVEN]     5
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[5]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 5
        // [THEN]                           / \                                    / \
        // [THEN]                          2 - 3                                  4 - 3
        // [THEN]                              |                                      |
        // [THEN]                              4                                      2
        // [THEN]                              |                                      |
        // [THEN]                              5                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Forward)", 4);
        RoutingLine[5].TestField("Sequence No. (Forward)", 5);

        RoutingLine[5].TestField("Sequence No. (Backward)", 1);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);
        RoutingLine[2].TestField("Sequence No. (Backward)", 4);
        RoutingLine[1].TestField("Sequence No. (Backward)", 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingDottedFilterInNextOperationNo()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Array[7] of Record "Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 340158] Sequence numbers on multiple parallel execution paths of different lengths. "Next Operation No." contains filter 2..5
        Initialize;

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2, 3, 4, 5 are executed in parallel.
        // [GIVEN] Ways: 1 -> 2 -> 7; 1 -> 3 -> 6 -> 7; 1 -> 4 -> 7; 1 -> 5 -> 7. Termination operation 7.
        // [GIVEN]      1
        // [GIVEN]  / /  \ \
        // [GIVEN] 2  3  4  5
        // [GIVEN]    |
        // [GIVEN]    6
        // [GIVEN]    |
        // [GIVEN]    7
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1..%2', RoutingLine[2]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[7]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[6]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[7]."Operation No.");
        SetNextOperationNo(RoutingLine[5], RoutingLine[7]."Operation No.");
        SetNextOperationNo(RoutingLine[6], RoutingLine[7]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)":    1           "Sequence No. (Backward)":  4
        // [THEN]                           / /  \ \                                 / /  \ \
        // [THEN]                          2  2  2  2                               2  3  2  2
        // [THEN]                             |                                        |
        // [THEN]                             3                                        2
        // [THEN]                             |                                        |
        // [THEN]                             4                                        1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[4].TestField("Sequence No. (Forward)", 2);
        RoutingLine[5].TestField("Sequence No. (Forward)", 2);
        RoutingLine[6].TestField("Sequence No. (Forward)", 3);
        RoutingLine[7].TestField("Sequence No. (Forward)", 4);

        RoutingLine[7].TestField("Sequence No. (Backward)", 1);
        RoutingLine[6].TestField("Sequence No. (Backward)", 2);
        RoutingLine[5].TestField("Sequence No. (Backward)", 2);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);
        RoutingLine[2].TestField("Sequence No. (Backward)", 2);
        RoutingLine[1].TestField("Sequence No. (Backward)", 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingWithCrossParallelOperations()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[6] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Verify sequence numbers on two parallel execution paths with cross-sections

        Initialize;

        // [GIVEN] Parallel routing with the following structure
        // [GIVEN]    1
        // [GIVEN]   / \
        // [GIVEN]  2   3
        // [GIVEN]  | X |
        // [GIVEN]  4   5
        // [GIVEN]   \ /
        // [GIVEN]    6
        // [GIVEN] Operation 4 and 5 are both executed in parallel after 2 and 3
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], StrSubstNo('%1|%2', RoutingLine[4]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[3], StrSubstNo('%1|%2', RoutingLine[4]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[4], RoutingLine[6]."Operation No.");
        SetNextOperationNo(RoutingLine[5], RoutingLine[6]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 4
        // [THEN]                           / \                                    / \
        // [THEN]                          2   2                                  3   3
        // [THEN]                          | X |                                  | X |
        // [THEN]                          3   3                                  2   2
        // [THEN]                           \ /                                    \ /
        // [THEN]                            4                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[1].TestField("Sequence No. (Backward)", 4);

        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[2].TestField("Sequence No. (Backward)", 3);

        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);

        RoutingLine[4].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);

        RoutingLine[5].TestField("Sequence No. (Forward)", 3);
        RoutingLine[5].TestField("Sequence No. (Backward)", 2);

        RoutingLine[6].TestField("Sequence No. (Forward)", 4);
        RoutingLine[6].TestField("Sequence No. (Backward)", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingFailedWithoutManualSequence()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if "Next Operation No." is not filled on operations

        Initialize;

        // [GIVEN] Create a parallel routing without filling the "Next Operation No." field
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[1], '', LibraryUtility.GenerateGUID, RoutingLine[1].Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[2], '', LibraryUtility.GenerateGUID, RoutingLine[2].Type::"Work Center", WorkCenter."No.");

        // [WHEN] Certify the routing
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Certification fails
        Assert.ExpectedError(StrSubstNo(WrongNoOfTerminationProcessesErr, RoutingHeader."No.", 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingFailedWithCircularReference()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail with an error message if the routing setup contains circular reference

        Initialize;

        // [GIVEN] Create a parallel routing with 3 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Starting operation 1, next operations 2 and 3 are executed in parallel.
        // [GIVEN] Next operation for op. 2 is 1 (circular reference)
        // [GIVEN]    --1
        // [GIVEN]   \ / \
        // [GIVEN]    2   3
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[1]."Operation No.");

        // [WHEN] Certify the routing
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Certification fails. Error message "Circular reference in routing" is thrown.
        Assert.ExpectedError(StrSubstNo(CircularReferenceErr, RoutingHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingNoStartingOperationFail()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if no starting operation is specified in the routing setup

        Initialize;

        // [GIVEN] Create parallel routing with two operations, set "Next Operation No." in both lines
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[1], '', LibraryUtility.GenerateGUID, RoutingLine[1].Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[2], '', LibraryUtility.GenerateGUID, RoutingLine[2].Type::"Work Center", WorkCenter."No.");

        SetNextOperationNo(RoutingLine[1], LibraryUtility.GenerateGUID);
        SetNextOperationNo(RoutingLine[2], LibraryUtility.GenerateGUID);

        // [WHEN] Certify the routing
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Certification fails.
        Assert.ExpectedError(NoLineWithinFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingTwoStartingOperationsFail()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if the routing setup contains two starting operations

        Initialize;

        // [GIVEN] Create parallel routing with 3 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] In operation 1 and 2, set "Next Operation No." = "3"
        // [GIVEN]  1   2
        // [GIVEN]   \ /
        // [GIVEN]    3
        SetNextOperationNo(RoutingLine[1], RoutingLine[3]."Operation No.");
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");

        // [WHEN] Certify the routing
        asserterror CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] Certification fails. Error message: "Actual number of starting processes is 2"
        Assert.ExpectedError(StrSubstNo(WrongNoOfStartProcessesErr, RoutingHeader."No.", 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingTwoTerminalOperationsFail()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if the routing setup contains two terminal operations

        Initialize;

        // [GIVEN] Create parallel routing with 3 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Starting operation - "1", operation "2" and "3" are executed in parallel after it
        // [GIVEN]    1
        // [GIVEN]   / \
        // [GIVEN]  2   3
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));

        // [WHEN] Certify the routing
        asserterror CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] Certification fails. Error message: "Actual number of termination processes is 2"
        Assert.ExpectedError(StrSubstNo(WrongNoOfTerminationProcessesErr, RoutingHeader."No.", 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PerformanceOnCerifyingParallelRouting()
    var
        CodeCoverage: Record "Code Coverage";
        SmallNoOfOperations: Integer;
        MediumNoOfOperations: Integer;
        LargeNoOfOperations: Integer;
        SmallNoOfHits: Integer;
        MediumNoOfHits: Integer;
        LargeNoOfHits: Integer;
    begin
        // [FEATURE] [Performance] [Parallel Routing]
        // [SCENARIO 221561] Calculation of routing operations sequence should have linear performance

        Initialize;

        // [GIVEN] Parallel routing with the following structure
        // [GIVEN]     1
        // [GIVEN]    / \
        // [GIVEN]   2   3
        // [GIVEN]    \ /
        // [GIVEN]     4
        // [GIVEN]    / \
        // [GIVEN]   5   6
        // [GIVEN]    \ /
        // [GIVEN]     7
        // [GIVEN]    / \
        // [GIVEN]    ...

        CodeCoverageMgt.StopApplicationCoverage;
        SmallNoOfOperations := 1;
        MediumNoOfOperations := 5;
        LargeNoOfOperations := 10;

        CodeCoverageMgt.StartApplicationCoverage;
        CreateAndCertifyRoutingWithCrossOperations(SmallNoOfOperations);
        CodeCoverageMgt.StopApplicationCoverage;
        SmallNoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceBack') +
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceForward');

        CodeCoverageMgt.StartApplicationCoverage;
        CreateAndCertifyRoutingWithCrossOperations(MediumNoOfOperations);
        CodeCoverageMgt.StopApplicationCoverage;
        MediumNoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceBack') +
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceForward');

        CodeCoverageMgt.StartApplicationCoverage;
        CreateAndCertifyRoutingWithCrossOperations(LargeNoOfOperations);
        CodeCoverageMgt.StopApplicationCoverage;
        LargeNoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceBack') +
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceForward');

        // [WHEN] Certify the routing
        // [THEN] Performance should be linear
        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(
            SmallNoOfOperations, MediumNoOfOperations, LargeNoOfOperations, SmallNoOfHits, MediumNoOfHits, LargeNoOfHits),
          NotLinearCCErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateCapacityOnChangingWorkCenterInParallelRouting()
    var
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Parallel Routing] [Capacity]
        // [SCENARIO 272988] Production order routing line is recalculated when the work center is changed for the parallel routing

        Initialize;

        // [GIVEN] Two work centers: "W1" with "Unit Cost" = 10, and "W2" with "Unit Cost" = 20 and "Overhead Rate" = 5
        CreateWorkCenterWithCost(WorkCenter[1], LibraryRandom.RandInt(10), 0);
        CreateWorkCenterWithCost(WorkCenter[2], LibraryRandom.RandIntInRange(15, 25), LibraryRandom.RandInt(5));

        // [GIVEN] Parallel routing with a single line on the work center "W1", "Run Time" = 30 min
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '100', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(100));
        RoutingLine.Modify(true);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item with the parallel routing assigned
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh a released production order for 3 pcs of the manufactured item
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(100));
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", '100');
        ProdOrderRoutingLine.FindFirst;

        // [WHEN] Open the prod. order routing and change the work center from "W1" to "W2"
        ProdOrderRoutingLine.Validate("No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Capacity requirements and costs are recalculated for the production order.
        // [THEN] Expected operation cost is 3 * 30 * 20 = 1800; Expected capacity overhead is 3 * 30 * 5 = 450
        ProdOrderRoutingLine.Find;
        ProdOrderRoutingLine.TestField(
          "Expected Operation Cost Amt.", ProductionOrder.Quantity * RoutingLine."Run Time" * WorkCenter[2]."Unit Cost");
        ProdOrderRoutingLine.TestField(
          "Expected Capacity Ovhd. Cost", ProductionOrder.Quantity * RoutingLine."Run Time" * WorkCenter[2]."Overhead Rate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityNotCalculatedOnChangingWorkCenterInNewLineParallelRouting()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 272988] Recalculation of the production order routing line is not triggered when a work center is selected in the new line for a parallel routing

        Initialize;

        // [GIVEN] Parallel routing with two operations: "100" and "200"
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '100', RoutingLine.Type::"Work Center", WorkCenter."No.");
        SetNextOperationNo(RoutingLine, '200');
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '200', RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item with the parallel routing and a released production order for this item
        CreateItemWithRouting(Item, RoutingHeader."No.");
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(100));

        // [GIVEN] Create new prod. order routing line for the same production order. The line does not have operation sequence defined, and thus would cause an error on capacity calculation
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        ProdOrderRoutingLine.Init;
        ProdOrderRoutingLine.Validate("Operation No.", '150');
        ProdOrderRoutingLine.Insert(true);

        // [WHEN] Set the work center no. in the new line
        ProdOrderRoutingLine.Validate("No.", WorkCenter."No.");

        // [THEN] Work center is updated without error
        ProdOrderRoutingLine.TestField("Work Center No.", WorkCenter."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingPersonnelCaptionMethodOverflow()
    var
        RoutingHeader: Record "Routing Header";
        RoutingPersonnel: Record "Routing Personnel";
        CaptionText: Text;
    begin
        // [SCENARIO 308562] Caption method throws OverflowError
        Initialize;

        // [GIVEN] Created "Routing Header" with MAXSTRLEN "No." and Description fields
        CreateRtngHeaderWithMaxStrlen(RoutingHeader);

        // [WHEN] Create "Routing Personnel" for this header with MAXSTRLEN "Operation No." field
        CreateRtngPersonnelWithMaxStrlen(RoutingPersonnel, RoutingHeader);
        RoutingPersonnel.SetFilter("Routing No.", RoutingHeader."No.");

        // [THEN] Caption method doesn't throw OverflowError and returns expected value
        CaptionText := StrSubstNo('%1 %2 %3', RoutingPersonnel."Routing No.",
            RoutingHeader.Description, RoutingPersonnel."Operation No.");
        Assert.AreEqual(CaptionText, RoutingPersonnel.Caption, '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeStatusProdOrderWithTrackingAndRoutingWithTwoLinesForward()
    var
        RoutingHeader: Record "Routing Header";
        WorkCenter: Record "Work Center";
        RoutingLine: array[2] of Record "Routing Line";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Location: Record Location;
        Index: Integer;
    begin
        // [FEATURE] [Item Tracking] [Order] [Status]
        // [SCENARIO 320285] Change status for Production Order which has Lot Tracked Item with Routing having multiple Lines with Flushing Method Forward
        Initialize;

        // [GIVEN] Certified Routing with two sequent Lines, each had Work Center with Flushing Method Forward
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for Index := 1 to ArrayLen(RoutingLine) do begin
            LibraryManufacturing.CreateWorkCenter(WorkCenter);
            WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Forward);
            WorkCenter.Modify(true);
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[Index], '', LibraryUtility.GenerateGUID, RoutingLine[1].Type::"Work Center", WorkCenter."No.");
        end;
        RoutingLine[1].Validate("Next Operation No.", RoutingLine[2]."Operation No.");
        RoutingLine[1].Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [GIVEN] Lot Tracked Item with the Routing
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);
        CreateItemWithRouting(Item, RoutingHeader."No.");
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Refreshed Planned Production Order with 10 PCS of the Item
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // [GIVEN] Fully tracked Prod. Order Line (done in ItemTrackingLinesModalPageHandler)
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst;
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID);
        LibraryVariableStorage.Enqueue(ProdOrderLine."Quantity (Base)");
        ProdOrderLine.OpenItemTrackingLines;

        // [WHEN] Change Order Status to Released
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate, false);

        // [THEN] Released Production Order for the Item is created
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.FindFirst;
        ProductionOrder.TestField(Status, ProductionOrder.Status::Released);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkCenterForCertifiedRouting()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [UT] [Work Center]
        // [SCENARIO 336623] Work Center cannot be deleted when it is a part of a certified routing

        // [GIVEN] Work Center "WKC"
        WorkCenter.Init;
        WorkCenter."No." := LibraryUtility.GenerateGUID;
        WorkCenter.Insert;

        // [GIVEN] Certified Routing "ROUT" with Routing Line for Work Center "WKC"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        MockRoutingLine(RoutingLine, RoutingHeader."No.", '', RoutingLine.Type::"Work Center", WorkCenter."No.");

        // [WHEN] Delete Work Center "WKC"
        asserterror WorkCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Work Center WKC because there is at least one certified routing associated with it"
        Assert.ExpectedError(StrSubstNo(CannotDeleteCertifiedRoutingExistsErr, RoutingLine.Type, WorkCenter."No.", 'routing'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkCenterForCertifiedRoutingVersion()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [UT] [Work Center]
        // [SCENARIO 336623] Work Center cannot be deleted when it is a part of a certified routing version

        // [GIVEN] Work Center "WKC"
        WorkCenter.Init;
        WorkCenter."No." := LibraryUtility.GenerateGUID;
        WorkCenter.Insert;

        // [GIVEN] Non-certified Routing "ROUT"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::"Under Development");

        // [GIVEN] Certified Routing Version "ROUT","V1" with Routing Line for Work Center "WKC"
        MockRoutingVersion(RoutingVersion, RoutingHeader."No.", RoutingVersion.Status::Certified);
        MockRoutingLine(
          RoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code",
          RoutingLine.Type::"Work Center", WorkCenter."No.");

        // [WHEN] Delete Work Center "WKC"
        asserterror WorkCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Work Center WKC because there is at least one certified routing version associated with it"
        Assert.ExpectedError(StrSubstNo(CannotDeleteCertifiedRoutingExistsErr, RoutingLine.Type, WorkCenter."No.", 'routing version'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteMachineCenterForCertifiedRouting()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
    begin
        // [FEATURE] [UT] [Machine Center]
        // [SCENARIO 336623] Machine Center cannot be deleted when it is a part of a certified routing

        // [GIVEN] Machine Center "MC"
        MachineCenter.Init;
        MachineCenter."No." := LibraryUtility.GenerateGUID;
        MachineCenter.Insert;

        // [GIVEN] Certified Routing "ROUT" with Routing Line for Machine Center "MC"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        MockRoutingLine(RoutingLine, RoutingHeader."No.", '', RoutingLine.Type::"Machine Center", MachineCenter."No.");

        // [WHEN] Delete Machine Center "MC"
        asserterror MachineCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Machine Center MC because there is at least one certified routing associated with it"
        Assert.ExpectedError(StrSubstNo(CannotDeleteCertifiedRoutingExistsErr, RoutingLine.Type, MachineCenter."No.", 'routing'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteMachineCenterForCertifiedRoutingVersion()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
    begin
        // [FEATURE] [UT] [Machine Center]
        // [SCENARIO 336623] Machine Center cannot be deleted when it is a part of a certified routing version

        // [GIVEN] Machine Center "MC"
        MachineCenter.Init;
        MachineCenter."No." := LibraryUtility.GenerateGUID;
        MachineCenter.Insert;

        // [GIVEN] Non-certified Routing "ROUT"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::"Under Development");

        // [GIVEN] Certified Routing Version "ROUT","V1" with Routing Line for Machine Center "MC"
        MockRoutingVersion(RoutingVersion, RoutingHeader."No.", RoutingVersion.Status::Certified);
        MockRoutingLine(
          RoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code",
          RoutingLine.Type::"Machine Center", MachineCenter."No.");

        // [WHEN] Delete Machine Center "C"
        asserterror MachineCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Machine Center MC because there is at least one certified routing version associated with it"
        Assert.ExpectedError(StrSubstNo(CannotDeleteCertifiedRoutingExistsErr, RoutingLine.Type, MachineCenter."No.", 'routing version'));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manufacturing - Routings");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manufacturing - Routings");

        UpdateManufSetupSetNormalStartingEndingTime;

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manufacturing - Routings");
    end;

    local procedure CreateRtngHeaderWithMaxStrlen(var RoutingHeader: Record "Routing Header")
    begin
        RoutingHeader.Init;
        RoutingHeader.Validate("No.", CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(RoutingHeader."No.")), 1));
        RoutingHeader.Validate(Description, LibraryUtility.GenerateRandomXMLText(MaxStrLen(RoutingHeader.Description)));
        RoutingHeader.Insert(true);
    end;

    [Normal]
    local procedure CreateRtngPersonnelWithMaxStrlen(var RoutingPersonnel: Record "Routing Personnel"; RoutingHeader: Record "Routing Header")
    begin
        RoutingPersonnel.Init;
        RoutingPersonnel.Validate("Routing No.", RoutingHeader."No.");
        RoutingPersonnel."Operation No." := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(RoutingPersonnel."Operation No.")), 1);
        RoutingPersonnel.Insert(true);
    end;

    local procedure CertifyRoutingAndRefreshLines(var RoutingHeader: Record "Routing Header"; var RoutingLine: array[6] of Record "Routing Line")
    var
        I: Integer;
    begin
        ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        for I := 1 to ArrayLen(RoutingLine) do
            RoutingLine[I].Find;
    end;

    local procedure ChangeRoutingStatus(var RoutingHeader: Record "Routing Header"; NewStatus: Option)
    begin
        RoutingHeader.Validate(Status, NewStatus);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndCertifyRoutingWithCrossOperations(NoOfOperations: Integer)
    var
        RoutingHeader: Record "Routing Header";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateRoutingLinesSequence(RoutingHeader, NoOfOperations);
        ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateRoutingLinesSequence(var RoutingHeader: Record "Routing Header"; NoOfRoutingBlocks: Integer)
    var
        WorkCenter: Record "Work Center";
        RoutingLine: array[4] of Record "Routing Line";
        PrevRoutingLine: Record "Routing Line";
        I: Integer;
        J: Integer;
    begin
        // To reproduce the performance bug, we need a "braided" routing consisting of blocks, 4 operations in each.
        // Each block has an entry and output operations, the other two in between are executed in parallel

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        for I := 1 to NoOfRoutingBlocks do begin
            for J := 1 to 4 do
                LibraryManufacturing.CreateRoutingLine(
                  RoutingHeader, RoutingLine[J], '', Format(4 * I + J), RoutingLine[J].Type::"Work Center", WorkCenter."No.");

            // If there is a previous block, connect it with the next one
            if PrevRoutingLine."Operation No." <> '' then
                SetNextOperationNo(PrevRoutingLine, RoutingLine[1]."Operation No.");

            SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
            SetNextOperationNo(RoutingLine[2], RoutingLine[4]."Operation No.");
            SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");

            PrevRoutingLine := RoutingLine[4];
        end;
    end;

    local procedure CreateWorkCenterWithCost(var WorkCenter: Record "Work Center"; UnitCost: Decimal; OverheadRate: Decimal)
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", UnitCost);
        WorkCenter.Validate("Overhead Rate", OverheadRate);
        WorkCenter.Modify(true);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
    begin
        CodeCoverageMgt.Refresh;
        with CodeCoverage do begin
            SetRange("Line Type", "Line Type"::Code);
            SetRange("Object Type", ObjectType);
            SetRange("Object ID", ObjectID);
            SetFilter("No. of Hits", '>%1', 0);
            SetFilter(Line, '@*' + CodeLine + '*');
            if FindSet then
                repeat
                    NoOfHits += "No. of Hits";
                until Next = 0;
        end;
    end;

    local procedure MockRoutingHeader(var RoutingHeader: Record "Routing Header"; Status: Option)
    begin
        RoutingHeader.Init;
        RoutingHeader."No." := LibraryUtility.GenerateGUID;
        RoutingHeader.Status := Status;
        RoutingHeader.Insert;
    end;

    local procedure MockRoutingVersion(var RoutingVersion: Record "Routing Version"; RoutingNo: Code[20]; Status: Option)
    begin
        RoutingVersion.Init;
        RoutingVersion."Routing No." := RoutingNo;
        RoutingVersion."Version Code" := LibraryUtility.GenerateGUID;
        RoutingVersion.Status := Status;
        RoutingVersion.Insert;
    end;

    local procedure MockRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; VersionCode: Code[20]; Type: Option; No: Code[20])
    begin
        RoutingLine.Init;
        RoutingLine."Routing No." := RoutingNo;
        RoutingLine."Version Code" := VersionCode;
        RoutingLine."Operation No." := LibraryUtility.GenerateGUID;
        RoutingLine.Type := Type;
        RoutingLine."No." := No;
        RoutingLine.Insert;
    end;

    local procedure SetNextOperationNo(var RoutingLine: Record "Routing Line"; NextOperationNo: Code[30])
    begin
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Modify(true);
    end;

    local procedure UpdateManufSetupSetNormalStartingEndingTime()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SetupUpdated: Boolean;
    begin
        ManufacturingSetup.Get;
        if ManufacturingSetup."Normal Starting Time" = 0T then begin
            ManufacturingSetup."Normal Starting Time" := 080000T;
            SetupUpdated := true;
        end;

        if ManufacturingSetup."Normal Ending Time" = 0T then begin
            ManufacturingSetup."Normal Ending Time" := 160000T;
            SetupUpdated := true;
        end;

        if SetupUpdated then
            ManufacturingSetup.Modify;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.First;
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText);
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueInteger);
        ItemTrackingLines.OK.Invoke;
    end;
}

