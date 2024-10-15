codeunit 10600 "Norwegian VAT Tools"
{

    trigger OnRun()
    begin
    end;

    var
        Text003: Label 'This will delete the current VAT Periods and create new.\Create the six standard Norwegian VAT Periods?';
        Text004: Label '%1 to %2';
        Text005: Label 'is in a settled and closed VAT period (%1 period %2)';
        Text006: Label '=%1 can only be used with Sale';
        Text007: Label '=%1 can only be used when posting without Tax';
        Text008: Label 'must be zero when posting outside tax area';
        Text009: Label 'must be zero when %1 in %2 is True';

    [Scope('OnPrem')]
    procedure GLEntryCalcPropDeduction(var PropDeductionVAT: Decimal; var PropDeductionVATACY: Decimal; GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; AddCurrGLEntryVATAmt: Decimal): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase) and
           VATPostingSetup."Calc. Prop. Deduction VAT" and
           (GLEntry.Amount <> 0)
        then begin
            // Calculate Amount adjustments
            PropDeductionVAT :=
              GLEntry."VAT Amount" - AdjustForPropDeduction(GLEntry."VAT Amount", GenJnlLine, VATPostingSetup);
            GLSetup.Get;
            if GenJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency" then
                PropDeductionVATACY :=
                  AddCurrGLEntryVATAmt - AdjustForPropDeduction(AddCurrGLEntryVATAmt, GenJnlLine, VATPostingSetup)
            else
                exit(false);
        end else begin
            PropDeductionVAT := 0;
            PropDeductionVATACY := 0;
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure AdjustForPropDeduction(Amount: Decimal; GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase) and
           VATPostingSetup."Calc. Prop. Deduction VAT" and
           (Amount <> 0)
        then
            exit(Round(Amount * VATPostingSetup."Proportional Deduction VAT %" / 100));
        exit(Amount);
    end;

    [Scope('OnPrem')]
    procedure VATEntrySetVATInfo(var VATEntry: Record "VAT Entry"; GenJnlLine: Record "Gen. Journal Line")
    var
        VATProdPostGrp: Record "VAT Product Posting Group";
        VATCode: Record "VAT Code";
    begin
        case GenJnlLine."VAT Base Amount Type" of
            GenJnlLine."VAT Base Amount Type"::Automatic:
                if VATEntry.Amount = 0 then begin
                    VATProdPostGrp.Get(GenJnlLine."VAT Prod. Posting Group");
                    if VATProdPostGrp."Outside Tax Area" then
                        VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"Outside Tax Area"
                    else
                        VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"Without VAT";
                end else
                    VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"With VAT";
            GenJnlLine."VAT Base Amount Type"::"With VAT":
                VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"With VAT";
            GenJnlLine."VAT Base Amount Type"::"Without VAT":
                VATEntry."Base Amount Type" := VATEntry."Base Amount Type"::"Without VAT";
        end;
        VATEntry."VAT Code" := GenJnlLine."VAT Code";

        // Test the Gen. Posting Type against the setup
        if VATEntry."VAT Code" <> '' then begin
            VATCode.Get(VATEntry."VAT Code");
            case VATCode."Test Gen. Posting Type" of
                VATCode."Test Gen. Posting Type"::Mandatory:
                    GenJnlLine.TestField("Gen. Posting Type");
                VATCode."Test Gen. Posting Type"::Same:
                    GenJnlLine.TestField("Gen. Posting Type", VATCode."Gen. Posting Type");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitVATCode_GenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; UseBalanceFields: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATCode: Record "VAT Code";
    begin
        with GenJnlLine do
            if UseBalanceFields then begin
                if VATPostingSetup.Get("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group") then begin
                    "Bal. VAT Code" := VATPostingSetup."VAT Code";
                    if VATPostingSetup."VAT Code" <> '' then begin
                        VATCode.Get(VATPostingSetup."VAT Code");
                        "Bal. Gen. Posting Type" := VATCode."Gen. Posting Type";
                    end;
                end else
                    "Bal. VAT Code" := '';
            end else begin
                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                    "VAT Code" := VATPostingSetup."VAT Code";
                    if VATPostingSetup."VAT Code" <> '' then begin
                        VATCode.Get(VATPostingSetup."VAT Code");
                        "Gen. Posting Type" := VATCode."Gen. Posting Type";
                    end;
                end else
                    "VAT Code" := '';
            end;
    end;

    [Scope('OnPrem')]
    procedure InitVATCode_SalesLine(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATCode: Record "VAT Code";
    begin
        if VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then begin
            SalesLine."VAT Code" := VATPostingSetup."VAT Code";
            if VATPostingSetup."VAT Code" <> '' then
                VATCode.Get(VATPostingSetup."VAT Code");
        end else
            SalesLine."VAT Code" := '';
    end;

    [Scope('OnPrem')]
    procedure InitVATCode_PurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATCode: Record "VAT Code";
    begin
        if VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then begin
            PurchaseLine."VAT Code" := VATPostingSetup."VAT Code";
            if VATPostingSetup."VAT Code" <> '' then
                VATCode.Get(VATPostingSetup."VAT Code");
        end else
            PurchaseLine."VAT Code" := '';
    end;

    [Scope('OnPrem')]
    procedure InitPostingGrps_GenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; UseBalanceFields: Boolean)
    var
        VATCode: Record "VAT Code";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GenJnlLine do
            if UseBalanceFields then
                if "Bal. VAT Code" = '' then begin
                    Validate("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                    Validate("Bal. VAT Bus. Posting Group", '');
                    Validate("Bal. VAT Prod. Posting Group", '');
                end else begin
                    VATCode.Get("Bal. VAT Code");
                    VATPostingSetup.SetCurrentKey("VAT Code");
                    VATPostingSetup.SetRange("VAT Code", "Bal. VAT Code");
                    VATPostingSetup.FindFirst;
                    Validate("Bal. Gen. Posting Type", VATCode."Gen. Posting Type");
                    Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                    Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                end
            else
                if "VAT Code" = '' then begin
                    Validate("Gen. Posting Type", "Gen. Posting Type"::" ");
                    Validate("VAT Bus. Posting Group", '');
                    Validate("VAT Prod. Posting Group", '');
                end else begin
                    VATCode.Get("VAT Code");
                    VATPostingSetup.SetCurrentKey("VAT Code");
                    VATPostingSetup.SetRange("VAT Code", "VAT Code");
                    VATPostingSetup.FindFirst;
                    Validate("Gen. Posting Type", VATCode."Gen. Posting Type");
                    Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                    Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                end;
    end;

    [Scope('OnPrem')]
    procedure InitPostingGrps_SalesLine(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if SalesLine."VAT Code" = '' then begin
            SalesLine.Validate("VAT Bus. Posting Group", '');
            SalesLine.Validate("VAT Prod. Posting Group", '');
        end else begin
            VATPostingSetup.SetCurrentKey("VAT Code");
            VATPostingSetup.SetRange("VAT Code", SalesLine."VAT Code");
            VATPostingSetup.FindFirst;
            SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            SalesLine.Validate("VAT Bus. Posting Group");
            SalesLine.Validate("VAT Prod. Posting Group");
        end;
    end;

    [Scope('OnPrem')]
    procedure InitPostingGrps_PurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if PurchaseLine."VAT Code" = '' then begin
            PurchaseLine.Validate("VAT Bus. Posting Group", '');
            PurchaseLine.Validate("VAT Prod. Posting Group", '');
        end else begin
            VATPostingSetup.SetCurrentKey("VAT Code");
            VATPostingSetup.SetRange("VAT Code", PurchaseLine."VAT Code");
            VATPostingSetup.FindFirst;
            PurchaseLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            PurchaseLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            PurchaseLine.Validate("VAT Bus. Posting Group");
            PurchaseLine.Validate("VAT Prod. Posting Group");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateStdVATPeriods(AskUser: Boolean)
    var
        VATPeriod: Record "VAT Period";
        Date: Record Date;
        PeriodNo: Integer;
        MonthName1: Text[30];
        MonthName2: Text[30];
    begin
        // Create Norwegian std. six VAT Periods
        if AskUser then
            if not Confirm(Text003) then
                exit;
        VATPeriod.DeleteAll;
        for PeriodNo := 1 to 6 do begin
            VATPeriod.Validate("Period No.", PeriodNo);
            VATPeriod.Validate("Start Day", 1);
            VATPeriod.Validate("Start Month", 2 * PeriodNo - 1);

            // Find month names
            Date.SetRange("Period Type", Date."Period Type"::Month);
            Date.SetRange("Period Start", DMY2Date(1, PeriodNo * 2 - 1, 2000), 20010101D);
            Date.FindSet;
            MonthName1 := Date."Period Name";
            Date.Next;
            MonthName2 := Date."Period Name";

            VATPeriod.Validate(Description, StrSubstNo(Text004, MonthName1, MonthName2));
            VATPeriod.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure FirstDateInVATPeriod(DateInPeriod: Date): Date
    var
        VATPeriod: Record "VAT Period";
        Day: Integer;
        Month: Integer;
    begin
        if Format(DateInPeriod) = '' then
            exit(20000101D);
        Day := Date2DMY(DateInPeriod, 1);
        Month := Date2DMY(DateInPeriod, 2);
        VATPeriod.CheckPeriods;
        VATPeriod.SetCurrentKey("Start Month", "Start Day");
        VATPeriod.SetRange("Start Month", 0, Month);
        VATPeriod.SetRange("Start Day", 0, Day);
        VATPeriod.FindLast;
        exit(DMY2Date(VATPeriod."Start Day", VATPeriod."Start Month", Date2DMY(DateInPeriod, 3)));
    end;

    [Scope('OnPrem')]
    procedure VATPeriodNo(DateInPeriod: Date): Integer
    var
        VATPeriod: Record "VAT Period";
        Day: Integer;
        Month: Integer;
    begin
        Day := Date2DMY(DateInPeriod, 1);
        Month := Date2DMY(DateInPeriod, 2);
        VATPeriod.CheckPeriods;
        VATPeriod.SetCurrentKey("Start Month", "Start Day");
        VATPeriod.SetRange("Start Month", 0, Month);
        VATPeriod.SetRange("Start Day", 0, Day);
        VATPeriod.FindLast;
        exit(VATPeriod."Period No.");
    end;

    [Scope('OnPrem')]
    procedure RunCheckNorwegianVAT(GenJnlLine: Record "Gen. Journal Line"; var AllowPostingInClosedVATPeriod: Boolean)
    var
        SettledVATPeriod: Record "Settled VAT Period";
        VATProdPostGrp: Record "VAT Product Posting Group";
        GLSetup: Record "General Ledger Setup";
    begin
        with GenJnlLine do begin
            if AllowPostingInClosedVATPeriod then
                AllowPostingInClosedVATPeriod := false
            else
                if SettledVATPeriod.Get(Date2DMY("Posting Date", 3), VATPeriodNo("Posting Date")) then
                    if SettledVATPeriod.Closed then
                        FieldError("Posting Date", StrSubstNo(Text005, SettledVATPeriod.Year, SettledVATPeriod."Period No."));

            if "VAT Base Amount Type" <> "VAT Base Amount Type"::Automatic then begin
                if ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) or
                   ("Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::Purchase)
                then
                    FieldError("VAT Base Amount Type", StrSubstNo(Text006, "VAT Base Amount Type"));
                if ("VAT Amount" <> 0) or ("Bal. VAT Amount" <> 0) then
                    FieldError("VAT Base Amount Type", StrSubstNo(Text007, "VAT Base Amount Type"));
            end;

            // VAT not possible Outside Tax Area
            if "VAT Prod. Posting Group" <> '' then begin
                VATProdPostGrp.Get("VAT Prod. Posting Group");
                if VATProdPostGrp."Outside Tax Area" and ("VAT Amount" <> 0) then
                    FieldError("VAT Amount", Text008);
            end;
            if "Bal. VAT Prod. Posting Group" <> '' then begin
                VATProdPostGrp.Get("Bal. VAT Prod. Posting Group");
                if VATProdPostGrp."Outside Tax Area" and ("Bal. VAT Amount" <> 0) then
                    FieldError("Bal. VAT Amount", Text008);
            end;

            // VAT other than Reverse Charge is not possible if the company is Not VAT xxx
            GLSetup.Get;
            if GLSetup."Non-Taxable" then begin
                if ("VAT Amount" <> 0) and ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT") then
                    FieldError("VAT Amount", StrSubstNo(Text009, GLSetup.FieldCaption("Non-Taxable"), GLSetup.TableCaption));
                if ("Bal. VAT Amount" <> 0) and ("Bal. VAT Calculation Type" <> "Bal. VAT Calculation Type"::"Reverse Charge VAT") then
                    FieldError("Bal. VAT Amount", StrSubstNo(Text009, GLSetup.FieldCaption("Non-Taxable"), GLSetup.TableCaption));
            end;
        end;
    end;
}

