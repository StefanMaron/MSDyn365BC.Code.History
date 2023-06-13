codeunit 5802 "Inventory Posting To G/L"
{
    Permissions = TableData "G/L Account" = r,
                  TableData "Invt. Posting Buffer" = rimd,
                  TableData "Value Entry" = rm,
                  TableData "G/L - Item Ledger Relation" = rimd;
    TableNo = "Value Entry";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, GlobalPostPerPostGroup, IsHandled);
        if IsHandled then
            exit;

        if GlobalPostPerPostGroup then
            PostInvtPostBuf(Rec, "Document No.", '', '', true)
        else
            PostInvtPostBuf(
              Rec,
              "Document No.",
              "External Document No.",
              CopyStr(
                StrSubstNo(Text000, "Entry Type", "Source No.", "Posting Date"),
                1, MaxStrLen(GenJnlLine.Description)),
              false);

        OnAfterRun(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        Currency: Record Currency;
        SourceCodeSetup: Record "Source Code Setup";
        TempGlobalInvtPostingBuffer: Record "Invt. Posting Buffer" temporary;
        TempInvtPostBuf: array[20] of Record "Invt. Posting Buffer" temporary;
        TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary;
        TempGLItemLedgRelation: Record "G/L - Item Ledger Relation" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        DimMgt: Codeunit DimensionManagement;
        COGSAmt: Decimal;
        InvtAdjmtAmt: Decimal;
        DirCostAmt: Decimal;
        OvhdCostAmt: Decimal;
        VarPurchCostAmt: Decimal;
        VarMfgDirCostAmt: Decimal;
        VarMfgOvhdCostAmt: Decimal;
        WIPInvtAmt: Decimal;
        InvtAmt: Decimal;
        TotalCOGSAmt: Decimal;
        TotalInvtAdjmtAmt: Decimal;
        TotalDirCostAmt: Decimal;
        TotalOvhdCostAmt: Decimal;
        TotalVarPurchCostAmt: Decimal;
        TotalVarMfgDirCostAmt: Decimal;
        TotalVarMfgOvhdCostAmt: Decimal;
        TotalWIPInvtAmt: Decimal;
        TotalInvtAmt: Decimal;
        GlobalInvtPostBufEntryNo: Integer;
        PostBufDimNo: Integer;
        GLSetupRead: Boolean;
        SourceCodeSetupRead: Boolean;
        InvtSetupRead: Boolean;
        Text000: Label '%1 %2 on %3';
        Text001: Label '%1 - %2, %3,%4,%5,%6';
        Text002: Label 'The following combination %1 = %2, %3 = %4, and %5 = %6 is not allowed.';
        RunOnlyCheck: Boolean;
        RunOnlyCheckSaved: Boolean;
        CalledFromItemPosting: Boolean;
        CalledFromTestReport: Boolean;
        GlobalPostPerPostGroup: Boolean;
        Text003: Label '%1 %2';
        GlobalJnlTemplName: Code[10];
        GlobalJnlBatchName: Code[10];

    procedure Initialize(PostPerPostGroup: Boolean)
    begin
        GlobalPostPerPostGroup := PostPerPostGroup;
        GlobalInvtPostBufEntryNo := 0;
    end;

    procedure SetGenJnlBatch(JnlTemplName: Code[10]; JnlBatchName: Code[10])
    begin
        GlobalJnlTemplName := JnlTemplName;
        GlobalJnlBatchName := JnlBatchName;
    end;

    procedure SetRunOnlyCheck(SetCalledFromItemPosting: Boolean; SetCheckOnly: Boolean; SetCalledFromTestReport: Boolean)
    begin
        CalledFromItemPosting := SetCalledFromItemPosting;
        RunOnlyCheck := SetCheckOnly;
        CalledFromTestReport := SetCalledFromTestReport;

        TempGLItemLedgRelation.Reset();
        TempGLItemLedgRelation.DeleteAll();
    end;

    procedure BufferInvtPosting(var ValueEntry: Record "Value Entry"): Boolean
    var
        CostToPost: Decimal;
        CostToPostACY: Decimal;
        ExpCostToPost: Decimal;
        ExpCostToPostACY: Decimal;
        PostToGL: Boolean;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferInvtPosting(ValueEntry, Result, IsHandled, RunOnlyCheck, CalledFromTestReport);
        if IsHandled then
            exit(Result);

        with ValueEntry do begin
            GetGLSetup();
            GetInvtSetup();
            if (not InvtSetup."Expected Cost Posting to G/L") and
               ("Expected Cost Posted to G/L" = 0) and
               "Expected Cost"
            then
                exit(false);

            if not ("Entry Type" in ["Entry Type"::"Direct Cost", "Entry Type"::Revaluation]) and
               not CalledFromTestReport
            then begin
                TestField("Expected Cost", false);
                TestField("Cost Amount (Expected)", 0);
                TestField("Cost Amount (Expected) (ACY)", 0);
            end;

            if InvtSetup."Expected Cost Posting to G/L" then begin
                CalcCostToPost(ExpCostToPost, "Cost Amount (Expected)", "Expected Cost Posted to G/L", PostToGL);
                CalcCostToPost(ExpCostToPostACY, "Cost Amount (Expected) (ACY)", "Exp. Cost Posted to G/L (ACY)", PostToGL);
            end;
            CalcCostToPost(CostToPost, "Cost Amount (Actual)", "Cost Posted to G/L", PostToGL);
            CalcCostToPost(CostToPostACY, "Cost Amount (Actual) (ACY)", "Cost Posted to G/L (ACY)", PostToGL);
            OnAfterCalcCostToPostFromBuffer(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, PostToGL);
            PostBufDimNo := 0;

            RunOnlyCheckSaved := RunOnlyCheck;
            if not PostToGL then
                exit(false);

            OnBeforeBufferPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);

            case "Item Ledger Entry Type" of
                "Item Ledger Entry Type"::Purchase:
                    BufferPurchPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
                "Item Ledger Entry Type"::Sale:
                    BufferSalesPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
                "Item Ledger Entry Type"::"Positive Adjmt.",
                "Item Ledger Entry Type"::"Negative Adjmt.",
                "Item Ledger Entry Type"::Transfer:
                    BufferAdjmtPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
                "Item Ledger Entry Type"::Consumption:
                    BufferConsumpPosting(ValueEntry, CostToPost, CostToPostACY);
                "Item Ledger Entry Type"::Output:
                    BufferOutputPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
                "Item Ledger Entry Type"::"Assembly Consumption":
                    BufferAsmConsumpPosting(ValueEntry, CostToPost, CostToPostACY);
                "Item Ledger Entry Type"::"Assembly Output":
                    BufferAsmOutputPosting(ValueEntry, CostToPost, CostToPostACY);
                "Item Ledger Entry Type"::" ":
                    BufferCapacityPosting(ValueEntry, CostToPost, CostToPostACY);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;

            OnAfterBufferPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
        end;

        if UpdateGlobalInvtPostBuf(ValueEntry."Entry No.") then
            exit(true);
        exit(CalledFromTestReport);
    end;

    local procedure BufferPurchPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferPurchPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            case "Entry Type" of
                "Entry Type"::"Direct Cost":
                    begin
                        if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                              TempGlobalInvtPostingBuffer."Account Type"::"Invt. Accrual (Interim)",
                              ExpCostToPost, ExpCostToPostACY, true);
                        if (CostToPost <> 0) or (CostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Applied",
                              CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::"Indirect Cost":
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                      CostToPost, CostToPostACY, false);
                "Entry Type"::Variance:
                    begin
                        TestField("Variance Type", "Variance Type"::Purchase);
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                          TempGlobalInvtPostingBuffer."Account Type"::"Purchase Variance",
                          CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::Revaluation:
                    begin
                        if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                              TempGlobalInvtPostingBuffer."Account Type"::"Invt. Accrual (Interim)",
                              ExpCostToPost, ExpCostToPostACY, true);
                        if (CostToPost <> 0) or (CostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                              CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::Rounding:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;
    end;

    local procedure BufferSalesPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferSalesPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            case "Entry Type" of
                "Entry Type"::"Direct Cost":
                    begin
                        if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                              TempGlobalInvtPostingBuffer."Account Type"::"COGS (Interim)",
                              ExpCostToPost, ExpCostToPostACY, true);
                        if (CostToPost <> 0) or (CostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::COGS,
                              CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::Revaluation:
                    begin
                        if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                              TempGlobalInvtPostingBuffer."Account Type"::"COGS (Interim)",
                              ExpCostToPost, ExpCostToPostACY, true);
                        if (CostToPost <> 0) or (CostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                              CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::Rounding:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;

        OnAfterBufferSalesPosting(TempInvtPostBuf, ValueEntry, PostBufDimNo);
    end;

    local procedure BufferOutputPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferOutputPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            case "Entry Type" of
                "Entry Type"::"Direct Cost":
                    begin
                        if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                              TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                              ExpCostToPost, ExpCostToPostACY, true);
                        if (CostToPost <> 0) or (CostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                              CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::"Indirect Cost":
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                      CostToPost, CostToPostACY, false);
                "Entry Type"::Variance:
                    case "Variance Type" of
                        "Variance Type"::Material:
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Material Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::Capacity:
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Capacity Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::Subcontracted:
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Subcontracted Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::"Capacity Overhead":
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Cap. Overhead Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::"Manufacturing Overhead":
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Mfg. Overhead Variance",
                              CostToPost, CostToPostACY, false);
                        else
                            ErrorNonValidCombination(ValueEntry);
                    end;
                "Entry Type"::Revaluation:
                    begin
                        if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                              TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                              ExpCostToPost, ExpCostToPostACY, true);
                        if (CostToPost <> 0) or (CostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                              CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::Rounding:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;

        OnAfterBufferOutputPosting(ValueEntry, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY);
    end;

    local procedure BufferConsumpPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferConsumpPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            case "Entry Type" of
                "Entry Type"::"Direct Cost":
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                      CostToPost, CostToPostACY, false);
                "Entry Type"::Revaluation,
              "Entry Type"::Rounding:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;

        OnAfterBufferConsumpPosting(TempInvtPostBuf, ValueEntry, PostBufDimNo, CostToPost, CostToPostACY);
    end;

    local procedure BufferCapacityPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    begin
        with ValueEntry do
            if "Order Type" = "Order Type"::Assembly then
                case "Entry Type" of
                    "Entry Type"::"Direct Cost":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Applied",
                          CostToPost, CostToPostACY, false);
                    "Entry Type"::"Indirect Cost":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                          TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                          CostToPost, CostToPostACY, false);
                    else
                        ErrorNonValidCombination(ValueEntry);
                end
            else
                case "Entry Type" of
                    "Entry Type"::"Direct Cost":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                          TempGlobalInvtPostingBuffer."Account Type"::"Direct Cost Applied",
                          CostToPost, CostToPostACY, false);
                    "Entry Type"::"Indirect Cost":
                        InitInvtPostBuf(
                          ValueEntry,
                          TempGlobalInvtPostingBuffer."Account Type"::"WIP Inventory",
                          TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                          CostToPost, CostToPostACY, false);
                    else
                        ErrorNonValidCombination(ValueEntry);
                end;

        OnAfterBufferCapacityPosting(ValueEntry, CostToPost, CostToPostACY);
    end;

    local procedure BufferAsmOutputPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferAsmOutputPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            case "Entry Type" of
                "Entry Type"::"Direct Cost":
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                "Entry Type"::"Indirect Cost":
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Overhead Applied",
                      CostToPost, CostToPostACY, false);
                "Entry Type"::Variance:
                    case "Variance Type" of
                        "Variance Type"::Material:
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Material Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::Capacity:
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Capacity Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::Subcontracted:
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Subcontracted Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::"Capacity Overhead":
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Cap. Overhead Variance",
                              CostToPost, CostToPostACY, false);
                        "Variance Type"::"Manufacturing Overhead":
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Mfg. Overhead Variance",
                              CostToPost, CostToPostACY, false);
                        else
                            ErrorNonValidCombination(ValueEntry);
                    end;
                "Entry Type"::Revaluation:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                "Entry Type"::Rounding:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;
    end;

    local procedure BufferAsmConsumpPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBufferAsmConsumpPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            case "Entry Type" of
                "Entry Type"::"Direct Cost":
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                "Entry Type"::Revaluation,
              "Entry Type"::Rounding:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;
    end;

    local procedure BufferAdjmtPosting(ValueEntry: Record "Value Entry"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeBufferAdjmtPosting(ValueEntry, TempGlobalInvtPostingBuffer, CostToPost, CostToPostACY, ExpCostToPost, ExpCostToPostACY, IsHandled);
        if IsHandled then
            exit;

        with ValueEntry do
            case "Entry Type" of
                "Entry Type"::"Direct Cost":
                    begin
                        // Posting adjustments to Interim accounts (Service)
                        if (ExpCostToPost <> 0) or (ExpCostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory (Interim)",
                              TempGlobalInvtPostingBuffer."Account Type"::"COGS (Interim)",
                              ExpCostToPost, ExpCostToPostACY, true);
                        if (CostToPost <> 0) or (CostToPostACY <> 0) then
                            InitInvtPostBuf(
                              ValueEntry,
                              TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                              TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                              CostToPost, CostToPostACY, false);
                    end;
                "Entry Type"::Revaluation,
              "Entry Type"::Rounding:
                    InitInvtPostBuf(
                      ValueEntry,
                      TempGlobalInvtPostingBuffer."Account Type"::Inventory,
                      TempGlobalInvtPostingBuffer."Account Type"::"Inventory Adjmt.",
                      CostToPost, CostToPostACY, false);
                else
                    ErrorNonValidCombination(ValueEntry);
            end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            if GLSetup."Additional Reporting Currency" <> '' then
                Currency.Get(GLSetup."Additional Reporting Currency");
        end;
        GLSetupRead := true;
    end;

    local procedure GetInvtSetup()
    begin
        if not InvtSetupRead then
            InvtSetup.Get();
        InvtSetupRead := true;
    end;

    local procedure CalcCostToPost(var CostToPost: Decimal; AdjdCost: Decimal; var PostedCost: Decimal; var PostToGL: Boolean)
    begin
        CostToPost := AdjdCost - PostedCost;

        if CostToPost <> 0 then begin
            if not RunOnlyCheck then
                PostedCost := AdjdCost;
            PostToGL := true;
        end;
    end;

    procedure InitInvtPostBuf(ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean)
    begin
        OnBeforeInitInvtPostBuf(ValueEntry);

        InitInvtPostBufPerAccount(ValueEntry, AccType, BalAccType, CostToPost, CostToPostACY, InterimAccount, false);
        InitInvtPostBufPerAccount(ValueEntry, AccType, BalAccType, CostToPost, CostToPostACY, InterimAccount, true);

        OnAfterInitInvtPostBuf(ValueEntry);
    end;

    local procedure InitInvtPostBufPerAccount(var ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean; BalancingRecord: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitInvtPostBufPerAccount(ValueEntry, AccType, BalAccType, CostToPost, CostToPostACY, InterimAccount, BalancingRecord, IsHandled);
        if IsHandled then
            exit;

        PostBufDimNo := PostBufDimNo + 1;

        if BalancingRecord then begin
            SetAccNo(TempInvtPostBuf[PostBufDimNo], ValueEntry, BalAccType, AccType);
            SetPostBufAmounts(TempInvtPostBuf[PostBufDimNo], -CostToPost, -CostToPostACY, InterimAccount);
        end else begin
            SetAccNo(TempInvtPostBuf[PostBufDimNo], ValueEntry, AccType, BalAccType);
            SetPostBufAmounts(TempInvtPostBuf[PostBufDimNo], CostToPost, CostToPostACY, InterimAccount);
        end;

        TempInvtPostBuf[PostBufDimNo]."Dimension Set ID" := ValueEntry."Dimension Set ID";

        OnAfterInitTempInvtPostBuf(TempInvtPostBuf, ValueEntry, PostBufDimNo);
    end;

    local procedure CheckAccNo(var AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAcc(AccountNo, CalledFromItemPosting, IsHandled);
        if IsHandled then
            exit;

        if AccountNo = '' then
            exit;

        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then begin
            if CalledFromItemPosting then
                GLAccount.TestField(Blocked, false);
            if not CalledFromTestReport then
                AccountNo := '';
        end;
    end;

    local procedure SetAccNo(var InvtPostBuf: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type")
    var
        InvtPostingSetup: Record "Inventory Posting Setup";
        GenPostingSetup: Record "General Posting Setup";
        IsHandled: Boolean;
    begin
        with InvtPostBuf do begin
            "Account No." := '';
            "Account Type" := AccType;
            "Bal. Account Type" := BalAccType;
            "Location Code" := ValueEntry."Location Code";
            "Inventory Posting Group" :=
                GetInvPostingGroupCode(ValueEntry, AccType = "Account Type"::"WIP Inventory", ValueEntry."Inventory Posting Group");
            "Gen. Bus. Posting Group" := ValueEntry."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := ValueEntry."Gen. Prod. Posting Group";
            "Posting Date" := ValueEntry."Posting Date";

            IsHandled := false;
            OnBeforeGetInvtPostSetup(InvtPostingSetup, "Location Code", "Inventory Posting Group", GenPostingSetup, IsHandled, InvtPostBuf);
            if not IsHandled then
                if UseInvtPostSetup() then begin
                    if CalledFromItemPosting then
                        InvtPostingSetup.Get("Location Code", "Inventory Posting Group")
                    else
                        if not InvtPostingSetup.Get("Location Code", "Inventory Posting Group") then
                            exit;
                end else begin
                    if CalledFromItemPosting then
                        GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group")
                    else
                        if not GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                            exit;
                    if not CalledFromTestReport then
                        GenPostingSetup.TestField(Blocked, false);
                end;

            OnSetAccNoOnAfterGetPostingSetup(InvtPostBuf, InvtPostingSetup, GenPostingSetup, ValueEntry, UseInvtPostSetup());

            IsHandled := false;
            OnBeforeSetAccNo(InvtPostBuf, ValueEntry, AccType.AsInteger(), BalAccType.AsInteger(), CalledFromItemPosting, IsHandled);
            if not IsHandled then
                case "Account Type" of
                    "Account Type"::Inventory:
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetInventoryAccount()
                        else
                            "Account No." := InvtPostingSetup."Inventory Account";
                    "Account Type"::"Inventory (Interim)":
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetInventoryAccountInterim()
                        else
                            "Account No." := InvtPostingSetup."Inventory Account (Interim)";
                    "Account Type"::"WIP Inventory":
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetWIPAccount()
                        else
                            "Account No." := InvtPostingSetup."WIP Account";
                    "Account Type"::"Material Variance":
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetMaterialVarianceAccount()
                        else
                            "Account No." := InvtPostingSetup."Material Variance Account";
                    "Account Type"::"Capacity Variance":
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetCapacityVarianceAccount()
                        else
                            "Account No." := InvtPostingSetup."Capacity Variance Account";
                    "Account Type"::"Subcontracted Variance":
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetSubcontractedVarianceAccount()
                        else
                            "Account No." := InvtPostingSetup."Subcontracted Variance Account";
                    "Account Type"::"Cap. Overhead Variance":
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetCapOverheadVarianceAccount()
                        else
                            "Account No." := InvtPostingSetup."Cap. Overhead Variance Account";
                    "Account Type"::"Mfg. Overhead Variance":
                        if CalledFromItemPosting then
                            "Account No." := InvtPostingSetup.GetMfgOverheadVarianceAccount()
                        else
                            "Account No." := InvtPostingSetup."Mfg. Overhead Variance Account";
                    "Account Type"::"Inventory Adjmt.":
                        if CalledFromItemPosting then
                            "Account No." := GenPostingSetup.GetInventoryAdjmtAccount()
                        else
                            "Account No." := GenPostingSetup."Inventory Adjmt. Account";
                    "Account Type"::"Direct Cost Applied":
                        if CalledFromItemPosting then
                            "Account No." := GenPostingSetup.GetDirectCostAppliedAccount()
                        else
                            "Account No." := GenPostingSetup."Direct Cost Applied Account";
                    "Account Type"::"Overhead Applied":
                        if CalledFromItemPosting then
                            "Account No." := GenPostingSetup.GetOverheadAppliedAccount()
                        else
                            "Account No." := GenPostingSetup."Overhead Applied Account";
                    "Account Type"::"Purchase Variance":
                        if CalledFromItemPosting then
                            "Account No." := GenPostingSetup.GetPurchaseVarianceAccount()
                        else
                            "Account No." := GenPostingSetup."Purchase Variance Account";
                    "Account Type"::COGS:
                        if CalledFromItemPosting then
                            "Account No." := GenPostingSetup.GetCOGSAccount()
                        else
                            "Account No." := GenPostingSetup."COGS Account";
                    "Account Type"::"COGS (Interim)":
                        if CalledFromItemPosting then
                            "Account No." := GenPostingSetup.GetCOGSInterimAccount()
                        else
                            "Account No." := GenPostingSetup."COGS Account (Interim)";
                    "Account Type"::"Invt. Accrual (Interim)":
                        if CalledFromItemPosting then
                            "Account No." := GenPostingSetup.GetInventoryAccrualAccount()
                        else
                            "Account No." := GenPostingSetup."Invt. Accrual Acc. (Interim)";
                end;


            OnSetAccNoOnBeforeCheckAccNo(InvtPostBuf, InvtPostingSetup, GenPostingSetup, CalledFromItemPosting, ValueEntry);
            CheckAccNo("Account No.");

            OnAfterSetAccNo(InvtPostBuf, ValueEntry, CalledFromItemPosting);
        end;
    end;

    local procedure SetPostBufAmounts(var InvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean)
    begin
        with InvtPostBuf do begin
            "Interim Account" := InterimAccount;
            Amount := CostToPost;
            "Amount (ACY)" := CostToPostACY;
        end;
    end;

    local procedure UpdateGlobalInvtPostBuf(ValueEntryNo: Integer): Boolean
    var
        i: Integer;
        ShouldInsertTempGLItemLedgRelation: Boolean;
    begin
        with TempGlobalInvtPostingBuffer do begin
            if not CalledFromTestReport then
                for i := 1 to PostBufDimNo do
                    if TempInvtPostBuf[i]."Account No." = '' then begin
                        Clear(TempInvtPostBuf);
                        exit(false);
                    end;
            for i := 1 to PostBufDimNo do begin
                TempGlobalInvtPostingBuffer := TempInvtPostBuf[i];
                "Dimension Set ID" := TempInvtPostBuf[i]."Dimension Set ID";
                Negative := (TempInvtPostBuf[i].Amount < 0) or (TempInvtPostBuf[i]."Amount (ACY)" < 0);

                UpdateReportAmounts();
                if Find() then begin
                    Amount := Amount + TempInvtPostBuf[i].Amount;
                    "Amount (ACY)" := "Amount (ACY)" + TempInvtPostBuf[i]."Amount (ACY)";
                    OnUpdateGlobalInvtPostBufOnBeforeModify(TempGlobalInvtPostingBuffer, TempInvtPostBuf[i]);
                    Modify();
                end else begin
                    GlobalInvtPostBufEntryNo := GlobalInvtPostBufEntryNo + 1;
                    "Entry No." := GlobalInvtPostBufEntryNo;
                    Insert();
                end;
                ShouldInsertTempGLItemLedgRelation := not (RunOnlyCheck or CalledFromTestReport);
                OnUpdateGlobalInvtPostBufOnAfterCalcShouldInsertTempGLItemLedgRelation(TempGLItemLedgRelation, TempGlobalInvtPostingBuffer, ValueEntryNo, RunOnlyCheck, CalledFromTestReport, ShouldInsertTempGLItemLedgRelation);
                if ShouldInsertTempGLItemLedgRelation then begin
                    TempGLItemLedgRelation.Init();
                    TempGLItemLedgRelation."G/L Entry No." := "Entry No.";
                    TempGLItemLedgRelation."Value Entry No." := ValueEntryNo;
                    TempGLItemLedgRelation.Insert();
                    OnAfterBufferGLItemLedgRelation(TempGLItemLedgRelation, GlobalInvtPostBufEntryNo);
                end;
            end;
        end;
        Clear(TempInvtPostBuf);
        exit(true);
    end;

    local procedure UpdateReportAmounts()
    begin
        with TempGlobalInvtPostingBuffer do
            case "Account Type" of
                "Account Type"::Inventory, "Account Type"::"Inventory (Interim)":
                    InvtAmt += Amount;
                "Account Type"::"WIP Inventory":
                    WIPInvtAmt += Amount;
                "Account Type"::"Inventory Adjmt.":
                    InvtAdjmtAmt += Amount;
                "Account Type"::"Invt. Accrual (Interim)":
                    InvtAdjmtAmt += Amount;
                "Account Type"::"Direct Cost Applied":
                    DirCostAmt += Amount;
                "Account Type"::"Overhead Applied":
                    OvhdCostAmt += Amount;
                "Account Type"::"Purchase Variance":
                    VarPurchCostAmt += Amount;
                "Account Type"::COGS:
                    COGSAmt += Amount;
                "Account Type"::"COGS (Interim)":
                    COGSAmt += Amount;
                "Account Type"::"Material Variance", "Account Type"::"Capacity Variance",
              "Account Type"::"Subcontracted Variance", "Account Type"::"Cap. Overhead Variance":
                    VarMfgDirCostAmt += Amount;
                "Account Type"::"Mfg. Overhead Variance":
                    VarMfgOvhdCostAmt += Amount;
            end;

        OnAfteUpdateReportAmounts(TempGlobalInvtPostingBuffer, InvtAmt, InvtAdjmtAmt, VarMfgDirCostAmt);
    end;

    local procedure ErrorNonValidCombination(ValueEntry: Record "Value Entry")
    begin
        with ValueEntry do
            if CalledFromTestReport then
                InsertTempInvtPostToGLTestBuf(ValueEntry)
            else
                Error(
                  Text002,
                  FieldCaption("Item Ledger Entry Type"), "Item Ledger Entry Type",
                  FieldCaption("Entry Type"), "Entry Type",
                  FieldCaption("Expected Cost"), "Expected Cost")
    end;

    local procedure InsertTempInvtPostToGLTestBuf(ValueEntry: Record "Value Entry")
    begin
        with ValueEntry do begin
            TempInvtPostToGLTestBuf."Line No." := GetNextLineNo();
            TempInvtPostToGLTestBuf."Posting Date" := "Posting Date";
            TempInvtPostToGLTestBuf.Description := StrSubstNo(Text003, TableCaption(), "Entry No.");
            TempInvtPostToGLTestBuf.Amount := "Cost Amount (Actual)";
            TempInvtPostToGLTestBuf."Value Entry No." := "Entry No.";
            TempInvtPostToGLTestBuf."Dimension Set ID" := "Dimension Set ID";
            OnInsertTempInvtPostToGLTestBufOnBeforeInsert(TempInvtPostToGLTestBuf, ValueEntry);
            TempInvtPostToGLTestBuf.Insert();
        end;
    end;

    local procedure GetNextLineNo(): Integer
    var
        InvtPostToGLTestBuffer: Record "Invt. Post to G/L Test Buffer";
        LastLineNo: Integer;
    begin
        InvtPostToGLTestBuffer := TempInvtPostToGLTestBuf;
        if TempInvtPostToGLTestBuf.FindLast() then
            LastLineNo := TempInvtPostToGLTestBuf."Line No." + 10000
        else
            LastLineNo := 10000;
        TempInvtPostToGLTestBuf := InvtPostToGLTestBuffer;
        exit(LastLineNo);
    end;

    procedure PostInvtPostBufPerEntry(var ValueEntry: Record "Value Entry")
    var
        DummyGenJnlLine: Record "Gen. Journal Line";
    begin
        with ValueEntry do
            PostInvtPostBuf(
              ValueEntry,
              "Document No.",
              "External Document No.",
              CopyStr(
                StrSubstNo(Text000, "Entry Type", "Source No.", "Posting Date"),
                1, MaxStrLen(DummyGenJnlLine.Description)),
              false);
    end;

    procedure PostInvtPostBufPerPostGrp(DocNo: Code[20]; Desc: Text[50])
    var
        ValueEntry: Record "Value Entry";
    begin
        PostInvtPostBuf(ValueEntry, DocNo, '', Desc, true);
    end;

    local procedure PostInvtPostBuf(var ValueEntry: Record "Value Entry"; DocNo: Code[20]; ExternalDocNo: Code[35]; Desc: Text[100]; PostPerPostGrp: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with TempGlobalInvtPostingBuffer do begin
            Reset();
            OnPostInvtPostBufferOnBeforeFind(TempGlobalInvtPostingBuffer, TempGLItemLedgRelation, ValueEntry);
            if not FindSet() then
                exit;

            PostInvtPostBufInitGenJnlLine(GenJnlLine, ValueEntry, DocNo, ExternalDocNo, Desc);

            PostInvtPostBufProcessGlobalInvtPostBuf(GenJnlLine, ValueEntry, PostPerPostGrp);

            RunOnlyCheck := RunOnlyCheckSaved;
            OnPostInvtPostBufferOnAfterPostInvtPostBuf(TempGlobalInvtPostingBuffer, ValueEntry, CalledFromItemPosting, CalledFromTestReport, RunOnlyCheck, PostPerPostGrp);

            DeleteAll();
        end;
    end;

    local procedure PostInvtPostBufInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; DocNo: Code[20]; ExternalDocNo: Code[35]; Desc: Text[100])
    begin
        GenJnlLine.Init();
        GenJnlLine."Document No." := DocNo;
        GenJnlLine."External Document No." := ExternalDocNo;
        GenJnlLine.Description := Desc;
        GetSourceCodeSetup();
        GenJnlLine."Source Code" := SourceCodeSetup."Inventory Post Cost";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Job No." := ValueEntry."Job No.";
        GenJnlLine."Reason Code" := ValueEntry."Reason Code";
        GenJnlLine."Prod. Order No." := ValueEntry."Order No.";
        GetGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            if GlobalJnlTemplName <> '' then begin
                GenJnlLine."Journal Template Name" := GlobalJnlTemplName;
                GenJnlLine."Journal Batch Name" := GlobalJnlBatchName;
            end else begin
                GetInvtSetup();
                InvtSetup.TestField("Invt. Cost Jnl. Template Name");
                GenJnlLine."Journal Template Name" := InvtSetup."Invt. Cost Jnl. Template Name";
                GenJnlLine."Journal Batch Name" := InvtSetup."Invt. Cost Jnl. Batch Name";
            end;
        OnPostInvtPostBufOnAfterInitGenJnlLine(GenJnlLine, ValueEntry);
    end;

    local procedure PostInvtPostBufProcessGlobalInvtPostBuf(var GenJnlLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; PostPerPostGrp: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostInvtPostBufProcessGlobalInvtPostBuf(TempGlobalInvtPostingBuffer, GenJnlLine, ValueEntry, GenJnlPostLine, CalledFromItemPosting, PostPerPostGrp, IsHandled);
        if IsHandled then
            exit;

        with TempGlobalInvtPostingBuffer do
            repeat
                GenJnlLine.Validate("Posting Date", "Posting Date");
                GenJnlLine.Validate("VAT Reporting Date", ValueEntry."VAT Reporting Date");
                OnPostInvtPostBufOnBeforeSetAmt(GenJnlLine, ValueEntry, TempGlobalInvtPostingBuffer);
                if SetAmt(GenJnlLine, Amount, "Amount (ACY)") then begin
                    if PostPerPostGrp then
                        SetDesc(GenJnlLine, TempGlobalInvtPostingBuffer);
                    OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetDesc(GenJnlLine, TempGlobalInvtPostingBuffer);
                    GenJnlLine."Account No." := "Account No.";
                    GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      "Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code",
                      GenJnlLine."Shortcut Dimension 2 Code");
                    OnPostInvtPostBufOnAfterUpdateGlobalDimFromDimSetID(GenJnlLine, TempGlobalInvtPostingBuffer);
                    if not CalledFromTestReport then
                        if not RunOnlyCheck then begin
                            if not CalledFromItemPosting then
                                GenJnlPostLine.SetOverDimErr();
                            OnBeforePostInvtPostBuf(GenJnlLine, TempGlobalInvtPostingBuffer, ValueEntry, GenJnlPostLine);
                            PostGenJnlLine(GenJnlLine);
                        end else begin
                            OnBeforeCheckInvtPostBuf(GenJnlLine, TempGlobalInvtPostingBuffer, ValueEntry, GenJnlPostLine, GenJnlCheckLine);
                            CheckGenJnlLine(GenJnlLine);
                        end
                    else
                        InsertTempInvtPostToGLTestBuf(GenJnlLine, ValueEntry);
                end;
                OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetAmt(GenJnlLine);

                if not CalledFromTestReport and not RunOnlyCheck then
                    CreateGLItemLedgRelation(ValueEntry);
            until Next() = 0;
    end;

    local procedure GetSourceCodeSetup()
    begin
        if not SourceCodeSetupRead then
            SourceCodeSetup.Get();
        SourceCodeSetupRead := true;
    end;

    local procedure SetAmt(var GenJnlLine: Record "Gen. Journal Line"; Amt: Decimal; AmtACY: Decimal) HasAmountToPost: Boolean
    begin
        with GenJnlLine do begin
            "Additional-Currency Posting" := "Additional-Currency Posting"::None;
            Validate(Amount, Amt);

            GetGLSetup();
            if GLSetup."Additional Reporting Currency" <> '' then begin
                "Source Currency Code" := GLSetup."Additional Reporting Currency";
                "Source Currency Amount" := AmtACY;
                if (Amount = 0) and ("Source Currency Amount" <> 0) then begin
                    "Additional-Currency Posting" :=
                      "Additional-Currency Posting"::"Additional-Currency Amount Only";
                    Validate(Amount, "Source Currency Amount");
                    "Source Currency Amount" := 0;
                end;
            end;
        end;

        HasAmountToPost := (Amt <> 0) or (AmtACY <> 0);
        OnAfterSetAmt(GenJnlLine, Amt, AmtACY, HasAmountToPost);
    end;

    procedure SetDesc(var GenJnlLine: Record "Gen. Journal Line"; InvtPostBuf: Record "Invt. Posting Buffer")
    begin
        with InvtPostBuf do
            GenJnlLine.Description :=
              CopyStr(
                StrSubstNo(
                  Text001,
                  "Account Type", "Bal. Account Type",
                  "Location Code", "Inventory Posting Group",
                  "Gen. Bus. Posting Group", "Gen. Prod. Posting Group"),
                1, MaxStrLen(GenJnlLine.Description));

        OnAfterSetDesc(GenJnlLine, InvtPostBuf);
    end;

    local procedure InsertTempInvtPostToGLTestBuf(GenJnlLine: Record "Gen. Journal Line"; ValueEntry: Record "Value Entry")
    begin
        with GenJnlLine do begin
            TempInvtPostToGLTestBuf.Init();
            TempInvtPostToGLTestBuf."Line No." := GetNextLineNo();
            TempInvtPostToGLTestBuf."Posting Date" := "Posting Date";
            TempInvtPostToGLTestBuf."Document No." := "Document No.";
            TempInvtPostToGLTestBuf.Description := Description;
            TempInvtPostToGLTestBuf."Account No." := "Account No.";
            TempInvtPostToGLTestBuf.Amount := Amount;
            TempInvtPostToGLTestBuf."Source Code" := "Source Code";
            TempInvtPostToGLTestBuf."System-Created Entry" := true;
            TempInvtPostToGLTestBuf."Value Entry No." := ValueEntry."Entry No.";
            TempInvtPostToGLTestBuf."Additional-Currency Posting" := "Additional-Currency Posting";
            TempInvtPostToGLTestBuf."Source Currency Code" := "Source Currency Code";
            TempInvtPostToGLTestBuf."Source Currency Amount" := "Source Currency Amount";
            TempInvtPostToGLTestBuf."Inventory Account Type" := TempGlobalInvtPostingBuffer."Account Type";
            TempInvtPostToGLTestBuf."Dimension Set ID" := "Dimension Set ID";
            if TempGlobalInvtPostingBuffer.UseInvtPostSetup() then begin
                TempInvtPostToGLTestBuf."Location Code" := TempGlobalInvtPostingBuffer."Location Code";
                TempInvtPostToGLTestBuf."Invt. Posting Group Code" :=
                  GetInvPostingGroupCode(
                    ValueEntry,
                    TempInvtPostToGLTestBuf."Inventory Account Type" = TempInvtPostToGLTestBuf."Inventory Account Type"::"WIP Inventory",
                    TempGlobalInvtPostingBuffer."Inventory Posting Group")
            end else begin
                TempInvtPostToGLTestBuf."Gen. Bus. Posting Group" := TempGlobalInvtPostingBuffer."Gen. Bus. Posting Group";
                TempInvtPostToGLTestBuf."Gen. Prod. Posting Group" := TempGlobalInvtPostingBuffer."Gen. Prod. Posting Group";
            end;
            OnInsertTempInvtPostToGLTestBufOnBeforeTempInvtPostToGLTestBufInsert(TempInvtPostToGLTestBuf, GenJnlLine, ValueEntry);
            TempInvtPostToGLTestBuf.Insert();
        end;
    end;

    local procedure CreateGLItemLedgRelation(var ValueEntry: Record "Value Entry")
    var
        GLReg: Record "G/L Register";
    begin
        GenJnlPostLine.GetGLReg(GLReg);
        if GlobalPostPerPostGroup then begin
            TempGLItemLedgRelation.Reset();
            TempGLItemLedgRelation.SetRange("G/L Entry No.", TempGlobalInvtPostingBuffer."Entry No.");
            TempGLItemLedgRelation.FindSet();
            repeat
                ValueEntry.Get(TempGLItemLedgRelation."Value Entry No.");
                UpdateValueEntry(ValueEntry);
                CreateGLItemLedgRelationEntry(GLReg);
            until TempGLItemLedgRelation.Next() = 0;
        end else begin
            UpdateValueEntry(ValueEntry);
            CreateGLItemLedgRelationEntry(GLReg);
        end;
    end;

    local procedure CreateGLItemLedgRelationEntry(GLReg: Record "G/L Register")
    var
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
    begin
        GLItemLedgRelation.Init();
        GLItemLedgRelation."G/L Entry No." := GLReg."To Entry No.";
        GLItemLedgRelation."Value Entry No." := TempGLItemLedgRelation."Value Entry No.";
        GLItemLedgRelation."G/L Register No." := GLReg."No.";
        OnBeforeGLItemLedgRelationInsert(GLItemLedgRelation, TempGlobalInvtPostingBuffer, GLReg, TempGLItemLedgRelation);
        GLItemLedgRelation.Insert();
        OnAfterGLItemLedgRelationInsert();
        TempGLItemLedgRelation."G/L Entry No." := TempGlobalInvtPostingBuffer."Entry No.";
        TempGLItemLedgRelation.Delete();
    end;

    local procedure UpdateValueEntry(var ValueEntry: Record "Value Entry")
    begin
        with ValueEntry do begin
            if TempGlobalInvtPostingBuffer."Interim Account" then begin
                "Expected Cost Posted to G/L" := "Cost Amount (Expected)";
                "Exp. Cost Posted to G/L (ACY)" := "Cost Amount (Expected) (ACY)";
            end else begin
                "Cost Posted to G/L" := "Cost Amount (Actual)";
                "Cost Posted to G/L (ACY)" := "Cost Amount (Actual) (ACY)";
            end;
            OnUpdateValueEntryOnBeforeModify(ValueEntry, TempGlobalInvtPostingBuffer);
            if not CalledFromItemPosting then
                Modify();
        end;
    end;

    procedure GetTempInvtPostToGLTestBuf(var InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer")
    begin
        InvtPostToGLTestBuf.DeleteAll();
        if not TempInvtPostToGLTestBuf.FindSet() then
            exit;

        repeat
            InvtPostToGLTestBuf := TempInvtPostToGLTestBuf;
            InvtPostToGLTestBuf.Insert();
        until TempInvtPostToGLTestBuf.Next() = 0;
    end;

    procedure GetAmtToPost(var NewCOGSAmt: Decimal; var NewInvtAdjmtAmt: Decimal; var NewDirCostAmt: Decimal; var NewOvhdCostAmt: Decimal; var NewVarPurchCostAmt: Decimal; var NewVarMfgDirCostAmt: Decimal; var NewVarMfgOvhdCostAmt: Decimal; var NewWIPInvtAmt: Decimal; var NewInvtAmt: Decimal; GetTotal: Boolean)
    begin
        GetAmt(NewInvtAdjmtAmt, InvtAdjmtAmt, TotalInvtAdjmtAmt, GetTotal);
        GetAmt(NewDirCostAmt, DirCostAmt, TotalDirCostAmt, GetTotal);
        GetAmt(NewOvhdCostAmt, OvhdCostAmt, TotalOvhdCostAmt, GetTotal);
        GetAmt(NewVarPurchCostAmt, VarPurchCostAmt, TotalVarPurchCostAmt, GetTotal);
        GetAmt(NewVarMfgDirCostAmt, VarMfgDirCostAmt, TotalVarMfgDirCostAmt, GetTotal);
        GetAmt(NewVarMfgOvhdCostAmt, VarMfgOvhdCostAmt, TotalVarMfgOvhdCostAmt, GetTotal);
        GetAmt(NewWIPInvtAmt, WIPInvtAmt, TotalWIPInvtAmt, GetTotal);
        GetAmt(NewCOGSAmt, COGSAmt, TotalCOGSAmt, GetTotal);
        GetAmt(NewInvtAmt, InvtAmt, TotalInvtAmt, GetTotal);
    end;

    local procedure GetAmt(var NewAmt: Decimal; var Amt: Decimal; var TotalAmt: Decimal; GetTotal: Boolean)
    begin
        if GetTotal then
            NewAmt := TotalAmt
        else begin
            NewAmt := Amt;
            TotalAmt := TotalAmt + Amt;
            Amt := 0;
        end;
    end;

    procedure GetInvtPostBuf(var InvtPostBuf: Record "Invt. Posting Buffer")
    begin
        InvtPostBuf.DeleteAll();

        TempGlobalInvtPostingBuffer.Reset();
        if TempGlobalInvtPostingBuffer.FindSet() then
            repeat
                InvtPostBuf := TempGlobalInvtPostingBuffer;
                InvtPostBuf.Insert();
            until TempGlobalInvtPostingBuffer.Next() = 0;
    end;

    local procedure GetInvPostingGroupCode(ValueEntry: Record "Value Entry"; WIPInventory: Boolean; InvPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        if WIPInventory then begin
            OnBeforeGetInvPostingGroupCode(ValueEntry, InvPostingGroupCode);
            if (ValueEntry."Source Type" = ValueEntry."Source Type"::Item) and (ValueEntry."Source No." <> ValueEntry."Item No.") then begin
                Item.SetLoadFields("Inventory Posting Group");
                if Item.Get(ValueEntry."Source No.") then
                    exit(Item."Inventory Posting Group");
            end;
        end;

        exit(InvPostingGroupCode);
    end;

    procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlCheckLine.RunCheck(GenJnlLine);
    end;

    procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBufferCapacityPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBufferConsumpPosting(var TempInvtPostingBuffer: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; var PostBufDimNo: Integer; var CostToPost: Decimal; var CostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBufferOutputPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferSalesPosting(var TempInvtPostingBuffer: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; var PostBufDimNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCostToPostFromBuffer(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal; var PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGLItemLedgRelationInsert()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInitInvtPostBuf(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInitTempInvtPostBuf(var TempInvtPostBuf: array[20] of Record "Invt. Posting Buffer" temporary; ValueEntry: Record "Value Entry"; PostBufDimNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAccNo(var InvtPostingBuffer: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; CalledFromItemPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDesc(var GenJnlLine: Record "Gen. Journal Line"; var InvtPostBuf: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmt(var GenJnlLine: Record "Gen. Journal Line"; Amt: Decimal; AmtACY: Decimal; var HasAmountToPost: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeBufferAdjmtPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBufferInvtPosting(var ValueEntry: Record "Value Entry"; var Result: Boolean; var IsHandled: Boolean; RunOnlyCheck: Boolean; CalledFromTestReport: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeBufferOutputPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBufferPosting(var ValueEntry: Record "Value Entry"; var CostToPost: Decimal; var CostToPostACY: Decimal; var ExpCostToPost: Decimal; var ExpCostToPostACY: Decimal)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeBufferPurchPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeBufferSalesPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; CostToPost: Decimal; CostToPostACY: Decimal; ExpCostToPost: Decimal; ExpCostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAcc(var AccountNo: Code[20]; CalledFromItemPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvtPostBuf(var GenJournalLine: Record "Gen. Journal Line"; var InvtPostingBuffer: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvPostingGroupCode(var ValueEntry: Record "Value Entry"; var InvPostingGroupCode: Code[20])
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeInitInvtPostBuf(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeInitInvtPostBufPerAccount(var ValueEntry: Record "Value Entry"; AccType: Enum "Invt. Posting Buffer Account Type"; BalAccType: Enum "Invt. Posting Buffer Account Type"; CostToPost: Decimal; CostToPostACY: Decimal; InterimAccount: Boolean; BalancingRecord: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvtPostBuf(var GenJournalLine: Record "Gen. Journal Line"; var InvtPostingBuffer: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvtPostSetup(var InventoryPostingSetup: Record "Inventory Posting Setup"; var LocationCode: Code[10]; InventoryPostingGroup: Code[20]; var GenPostingSetup: Record "General Posting Setup"; var IsHandled: Boolean; var InvtPostingBuffer: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLItemLedgRelationInsert(var GLItemLedgerRelation: Record "G/L - Item Ledger Relation"; InvtPostingBuffer: Record "Invt. Posting Buffer"; GLRegister: Record "G/L Register"; TempGLItemLedgerRelation: Record "G/L - Item Ledger Relation" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvtPostBufProcessGlobalInvtPostBuf(var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var GenJnlLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CalledFromItemPosting: Boolean; PostPerPostGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAccNo(var InvtPostBuf: Record "Invt. Posting Buffer"; ValueEntry: Record "Value Entry"; AccType: Option; BalAccType: Option; CalledFromItemPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ValueEntry: Record "Value Entry"; PostPerPostGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempInvtPostToGLTestBufOnBeforeInsert(var TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempInvtPostToGLTestBufOnBeforeTempInvtPostToGLTestBufInsert(var TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary; GenJournalLine: Record "Gen. Journal Line"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnPostInvtPostBufferOnBeforeFind(var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; var TempGLItemLedgRelation: Record "G/L - Item Ledger Relation"; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufOnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufferOnAfterPostInvtPostBuf(var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; var ValueEntry: Record "Value Entry"; CalledFromItemPosting: Boolean; CalledFromTestReport: Boolean; RunOnlyCheck: Boolean; PostPerPostGrp: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufOnAfterUpdateGlobalDimFromDimSetID(var GenJournalLine: Record "Gen. Journal Line"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufOnBeforeSetAmt(var GenJournalLine: Record "Gen. Journal Line"; var ValueEntry: Record "Value Entry"; var GlobalInvtPostingBuffer: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetAmt(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtPostBufProcessGlobalInvtPostBufOnAfterSetDesc(var GenJournalLine: Record "Gen. Journal Line"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAccNoOnAfterGetPostingSetup(var InvtPostBuf: Record "Invt. Posting Buffer"; var InvtPostingSetup: Record "Inventory Posting Setup"; var GenPostingSetup: Record "General Posting Setup"; ValueEntry: Record "Value Entry"; UseInvtPostSetup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAccNoOnBeforeCheckAccNo(var InvtPostBuf: Record "Invt. Posting Buffer"; InvtPostingSetup: Record "Inventory Posting Setup"; GenPostingSetup: Record "General Posting Setup"; CalledFromItemPosting: Boolean; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGlobalInvtPostBufOnBeforeModify(var GlobalInvtPostBuf: Record "Invt. Posting Buffer"; TempInvtPostBuf: Record "Invt. Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGlobalInvtPostBufOnAfterCalcShouldInsertTempGLItemLedgRelation(var TempGLItemLedgerRelation: Record "G/L - Item Ledger Relation" temporary; TempInvtPostingBuffer: Record "Invt. Posting Buffer" temporary; ValueEntryNo: Integer; RunOnlyCheck: Boolean; CalledFromTestReport: Boolean; var ShouldInsertTempGLItemLedgRelation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBufferGLItemLedgRelation(var TempGLItemLedgRelation: Record "G/L - Item Ledger Relation" temporary; GlobalInvtPostBufEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateValueEntryOnBeforeModify(var ValueEntry: Record "Value Entry"; InvtPostingBuffer: Record "Invt. Posting Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferConsumpPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; CostToPost: Decimal; CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfteUpdateReportAmounts(var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var InvtAmt: Decimal; var InvtAdjmtAmt: Decimal; var VarMfgDirCostAmt: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferAsmOutputPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var CostToPost: Decimal; var CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBufferAsmConsumpPosting(var ValueEntry: Record "Value Entry"; var GlobalInvtPostBuf: Record "Invt. Posting Buffer" temporary; var CostToPost: Decimal; var CostToPostACY: Decimal; var IsHandled: Boolean)
    begin
    end;
}

