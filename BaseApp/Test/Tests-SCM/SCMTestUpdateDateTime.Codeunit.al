codeunit 137225 "SCM Test UpdateDateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Production Order] [Date-Time] [SCM] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5405()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        with ProductionOrder do begin
            SetNullNull("Starting Date", "Starting Time");
            SetNullNull("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetDateNull("Starting Date", "Starting Time");
            SetDateNull("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetNullTime("Starting Date", "Starting Time");
            SetNullTime("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetDateTime("Starting Date", "Starting Time");
            SetDateTime("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time");
            TestField("Ending Date-Time");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5406()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        Initialize();
        with ProdOrderLine do begin
            SetNullNull("Starting Date", "Starting Time");
            SetNullNull("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetNullTime("Starting Date", "Starting Time");
            SetNullTime("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetDateTime("Starting Date", "Starting Time");
            SetDateTime("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time");
            TestField("Ending Date-Time");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5407()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Initialize();
        with ProdOrderComponent do begin
            SetNullNull("Due Date", "Due Time");
            UpdateDatetime();
            TestField("Due Date-Time", 0DT);

            SetDateNull("Due Date", "Due Time");
            UpdateDatetime();
            TestField("Due Date-Time", 0DT);

            SetNullTime("Due Date", "Due Time");
            UpdateDatetime();
            TestField("Due Date-Time", 0DT);

            SetDateTime("Due Date", "Due Time");
            UpdateDatetime();
            TestField("Due Date-Time");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5409()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        Initialize();
        with ProdOrderRoutingLine do begin
            SetNullNull("Starting Date", "Starting Time");
            SetNullNull("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetDateNull("Starting Date", "Starting Time");
            SetDateNull("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetNullTime("Starting Date", "Starting Time");
            SetNullTime("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetDateTime("Starting Date", "Starting Time");
            SetDateTime("Ending Date", "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time");
            TestField("Ending Date-Time");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5410()
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        Initialize();
        with ProdOrderCapNeed do begin
            SetNullNull(Date, "Starting Time");
            SetNullNull(Date, "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetDateNull(Date, "Starting Time");
            SetDateNull(Date, "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetNullTime(Date, "Starting Time");
            SetNullTime(Date, "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time", 0DT);
            TestField("Ending Date-Time", 0DT);

            SetDateTime(Date, "Starting Time");
            SetDateTime(Date, "Ending Time");
            UpdateDatetime();
            TestField("Starting Date-Time");
            TestField("Ending Date-Time");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueTimeIsUpdatedWithDueDateOnProdOrderComp()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 230435] "Due Time" and "Due Date-Time" are updated on Prod. Order Component from related Prod. Order Line when "Due Date" is updated.
        Initialize();

        // [GIVEN] Prod. Order Line with "Due Date" = "D" and "Due Time" = "T".
        MockProdOrderLine(ProdOrderLine);

        with ProdOrderComponent do begin
            // [GIVEN] Prod. order component.
            "Prod. Order No." := ProdOrderLine."Prod. Order No.";
            "Qty. per Unit of Measure" := 1;
            Insert();

            // [WHEN] Validate "Calculation Formula" on the component to trigger copying due date and time from production order line.
            Validate("Calculation Formula");

            // [THEN] "Due Date" on the component = "D", "Due Time" = "T", "Due Date-Time" = "D" "T".
            TestField("Due Date", ProdOrderLine."Starting Date");
            TestField("Due Time", ProdOrderLine."Starting Time");
            TestField("Due Date-Time", CreateDateTime("Due Date", "Due Time"));
        end;
    end;

    local procedure SetNullNull(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := 0D;
        TimeVar := 0T;
    end;

    local procedure SetDateNull(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := DMY2Date(1, 1, 2001);
        TimeVar := 0T;
    end;

    local procedure SetNullTime(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := 0D;
        TimeVar := 111100T;
    end;

    local procedure SetDateTime(var DateVar: Date; var TimeVar: Time)
    begin
        DateVar := DMY2Date(1, 1, 2001);
        TimeVar := 111100T;
    end;

    local procedure MockProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        with ProdOrderLine do begin
            Init();
            "Prod. Order No." := LibraryUtility.GenerateGUID();
            "Starting Date" := WorkDate();
            "Starting Time" := 120000T;
            Insert();
        end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Test UpdateDateTime");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Test UpdateDateTime");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Test UpdateDateTime");
    end;
}

