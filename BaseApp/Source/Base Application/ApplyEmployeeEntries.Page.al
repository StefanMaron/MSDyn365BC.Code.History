page 234 "Apply Employee Entries"
{
    Caption = 'Apply Employee Entries';
    DataCaptionFields = "Employee No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    Permissions = TableData "Employee Ledger Entry" = m;
    PromotedActionCategories = 'New,Process,Report,Entry';
    SourceTable = "Employee Ledger Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TempApplyingEmplLedgEntry.""Posting Date"""; TempApplyingEmplLedgEntry."Posting Date")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the entry to be applied.';
                }
                field("TempApplyingEmplLedgEntry.""Document Type"""; TempApplyingEmplLedgEntry."Document Type")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the document type of the entry to be applied.';
                }
                field("TempApplyingEmplLedgEntry.""Document No."""; TempApplyingEmplLedgEntry."Document No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the document number of the entry to be applied.';
                }
                field(ApplyingEmployeeNo; TempApplyingEmplLedgEntry."Employee No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Employee No.';
                    Editable = false;
                    ToolTip = 'Specifies the employee number of the entry to be applied.';
                    Visible = false;
                }
                field(ApplyingDescription; TempApplyingEmplLedgEntry.Description)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry to be applied.';
                    Visible = false;
                }
                field("TempApplyingEmplLedgEntry.""Currency Code"""; TempApplyingEmplLedgEntry."Currency Code")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                }
                field("TempApplyingEmplLedgEntry.Amount"; TempApplyingEmplLedgEntry.Amount)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
                field("TempApplyingEmplLedgEntry.""Remaining Amount"""; TempApplyingEmplLedgEntry."Remaining Amount")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = AppliesToIDVisible;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s document type.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s document number.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the number of the employee account that the entry is linked to.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies a description of the employee entry.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original entry.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry.';
                    Visible = false;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("CalcApplnRemainingAmount(""Remaining Amount"")"; CalcApplnRemainingAmount("Remaining Amount"))
                {
                    ApplicationArea = BasicHR;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Remaining Amount';
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("Amount to Apply"; "Amount to Apply")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount to apply.';

                    trigger OnValidate()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);

                        if (xRec."Amount to Apply" = 0) or ("Amount to Apply" = 0) and
                           ((ApplnType = ApplnType::"Applies-to ID") or (CalcType = CalcType::Direct))
                        then
                            SetEmplApplId;
                        Get("Entry No.");
                        AmounttoApplyOnAfterValidate;
                    end;
                }
                field("CalcApplnAmounttoApply(""Amount to Apply"")"; CalcApplnAmounttoApply("Amount to Apply"))
                {
                    ApplicationArea = BasicHR;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Amount to Apply';
                    ToolTip = 'Specifies the amount to apply.';
                }
                field("Payment Reference"; "Payment Reference")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment to the employee.';
                }
                field(Open; Open)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
                }
                field(Positive; Positive)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies if the entry to be applied is positive.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
            }
            group(Control41)
            {
                ShowCaption = false;
                fixed(Control1903222401)
                {
                    ShowCaption = false;
                    group("Appln. Currency")
                    {
                        Caption = 'Appln. Currency';
                        field(ApplnCurrencyCode; ApplnCurrencyCode)
                        {
                            ApplicationArea = BasicHR;
                            Editable = false;
                            ShowCaption = false;
                            TableRelation = Currency;
                            ToolTip = 'Specifies the currency code that the amount will be applied in, in case of different currencies.';
                        }
                    }
                    group(Control1900545201)
                    {
                        Caption = 'Amount to Apply';
                        field(AmountToApply; AppliedAmount)
                        {
                            ApplicationArea = BasicHR;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Amount to Apply';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the amounts on all the selected employee ledger entries that will be applied by the entry shown in the Available Amount field. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group(Rounding)
                    {
                        Caption = 'Rounding';
                        field(ApplnRounding; ApplnRounding)
                        {
                            ApplicationArea = BasicHR;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Rounding';
                            Editable = false;
                            ToolTip = 'Specifies the rounding difference when you apply entries in different currencies to one another. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Applied Amount")
                    {
                        Caption = 'Applied Amount';
                        field(AppliedAmount; AppliedAmount + (-PmtDiscAmount) + ApplnRounding)
                        {
                            ApplicationArea = BasicHR;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Applied Amount';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the amounts in the Amount to Apply field, Pmt. Disc. Amount field, and the Rounding. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Available Amount")
                    {
                        Caption = 'Available Amount';
                        field(ApplyingAmount; ApplyingAmount)
                        {
                            ApplicationArea = BasicHR;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Available Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the journal entry, purchase credit memo, or current employee ledger entry that you have selected as the applying entry.';
                        }
                    }
                    group(Balance)
                    {
                        Caption = 'Balance';
                        field(ControlBalance; AppliedAmount + (-PmtDiscAmount) + ApplyingAmount + ApplnRounding)
                        {
                            ApplicationArea = BasicHR;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Balance';
                            Editable = false;
                            ToolTip = 'Specifies any extra amount that will remain after the application.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("Applied E&ntries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Applied Employee Entries";
                    RunPageOnRec = true;
                    ToolTip = 'View the ledger entries that have been applied to this record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Detailed Empl. Ledger Entries";
                    RunPageLink = "Employee Ledger Entry No." = FIELD("Entry No.");
                    RunPageView = SORTING("Employee Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of all the posted entries and adjustments related to a specific employee ledger entry.';
                }
                action(Navigate)
                {
                    ApplicationArea = BasicHR;
                    Caption = '&Navigate';
                    Image = Navigate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';
                    Visible = NOT IsOfficeAddin;

                    trigger OnAction()
                    begin
                        Navigate.SetDoc("Posting Date", "Document No.");
                        Navigate.Run;
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action(ActionSetAppliesToID)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Set Applies-to ID';
                    Image = SelectLineToApply;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Set the Applies-to ID field on the posted entry to automatically be filled in with the document number of the entry in the journal.';

                    trigger OnAction()
                    begin
                        if (CalcType = CalcType::GenJnlLine) and (ApplnType = ApplnType::"Applies-to Doc. No.") then
                            Error(CannotSetAppliesToIDErr);

                        SetEmplApplId;
                    end;
                }
                action(ActionPostApplication)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Post Application';
                    Ellipsis = true;
                    Image = PostApplication;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Define the document number of the ledger entry to use to perform the application. In addition, you specify the Posting Date for the application.';

                    trigger OnAction()
                    begin
                        PostDirectApplication(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        PostDirectApplication(true);
                    end;
                }
                separator("-")
                {
                    Caption = '-';
                }
                action("Show Only Selected Entries to Be Applied")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Show Only Selected Entries to Be Applied';
                    Image = ShowSelected;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'View the selected ledger entries that will be applied to the specified record.';

                    trigger OnAction()
                    begin
                        ShowAppliedEntries := not ShowAppliedEntries;
                        if ShowAppliedEntries then
                            if CalcType = CalcType::GenJnlLine then
                                SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
                            else begin
                                EmplEntryApplID := UserId;
                                if EmplEntryApplID = '' then
                                    EmplEntryApplID := '***';
                                SetRange("Applies-to ID", EmplEntryApplID);
                            end
                        else
                            SetRange("Applies-to ID");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ApplnType = ApplnType::"Applies-to Doc. No." then
            CalcApplnAmount;
    end;

    trigger OnInit()
    begin
        AppliesToIDVisible := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
        if "Applies-to ID" <> xRec."Applies-to ID" then
            CalcApplnAmount;
        exit(false);
    end;

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        if CalcType = CalcType::Direct then begin
            Empl.Get("Employee No.");
            ApplnCurrencyCode := '';
            FindApplyingEntry;
        end;

        AppliesToIDVisible := ApplnType <> ApplnType::"Applies-to Doc. No.";

        GLSetup.Get();

        if CalcType = CalcType::GenJnlLine then
            CalcApplnAmount;
        PostingDone := false;
        IsOfficeAddin := OfficeMgt.IsAvailable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush;
        if ApplnType = ApplnType::"Applies-to Doc. No." then begin
            if OK and (TempApplyingEmplLedgEntry."Posting Date" < "Posting Date") then begin
                OK := false;
                Error(
                  EarlierPostingDateErr, TempApplyingEmplLedgEntry."Document Type", TempApplyingEmplLedgEntry."Document No.",
                  "Document Type", "Document No.");
            end;
            if OK then begin
                if "Amount to Apply" = 0 then
                    "Amount to Apply" := "Remaining Amount";
                CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
            end;
        end;

        if CheckActionPerformed then begin
            Rec := TempApplyingEmplLedgEntry;
            "Applying Entry" := false;
            if AppliesToID = '' then begin
                "Applies-to ID" := '';
                "Amount to Apply" := 0;
            end;
            CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
        end;
    end;

    var
        TempApplyingEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        AppliedEmplLedgEntry: Record "Employee Ledger Entry";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        Empl: Record Employee;
        EmplLedgEntry: Record "Employee Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        EmplEntrySetApplID: Codeunit "Empl. Entry-SetAppl.ID";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        Navigate: Page Navigate;
        GenJnlLineApply: Boolean;
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        PmtDiscAmount: Decimal;
        ApplnDate: Date;
        ApplnCurrencyCode: Code[10];
        ApplnRoundingPrecision: Decimal;
        ApplnRounding: Decimal;
        ApplnType: Option " ","Applies-to Doc. No.","Applies-to ID";
        AmountRoundingPrecision: Decimal;
        CalcType: Option Direct,GenJnlLine,PurchHeader;
        EmplEntryApplID: Code[50];
        AppliesToID: Code[50];
        ValidExchRate: Boolean;
        DifferentCurrenciesInAppln: Boolean;
        MustSelectEntryErr: Label 'You must select an applying entry before you can post the application.';
        PostingInWrongContextErr: Label 'You must post the application from the window where you entered the applying entry.';
        CannotSetAppliesToIDErr: Label 'You cannot set Applies-to ID field while selecting Applies-to Doc. No field.';
        ShowAppliedEntries: Boolean;
        OK: Boolean;
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date.\\Instead, post the document of type %1 with the number %2 and then apply it to the document of type %3 with the number %4.', Comment = '%1 - document type, %2 - document number,%3 - document type,%4 - document number';
        PostingDone: Boolean;
        [InDataSet]
        AppliesToIDVisible: Boolean;
        ActionPerformed: Boolean;
        ApplicationPostedMsg: Label 'The application was successfully posted.';
        ApplicationDateErr: Label 'The posting date entered must not be before the posting date on the employee ledger entry.';
        ApplicationProcessCanceledErr: Label 'Post application process has been canceled.';
        IsOfficeAddin: Boolean;

    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line"; ApplnTypeSelect: Integer)
    begin
        GenJnlLine := NewGenJnlLine;
        GenJnlLineApply := true;

        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee then
            ApplyingAmount := GenJnlLine.Amount;
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee then
            ApplyingAmount := -GenJnlLine.Amount;
        ApplnDate := GenJnlLine."Posting Date";
        ApplnCurrencyCode := GenJnlLine."Currency Code";
        CalcType := CalcType::GenJnlLine;

        case ApplnTypeSelect of
            GenJnlLine.FieldNo("Applies-to Doc. No."):
                ApplnType := ApplnType::"Applies-to Doc. No.";
            GenJnlLine.FieldNo("Applies-to ID"):
                ApplnType := ApplnType::"Applies-to ID";
        end;

        SetApplyingEmplLedgEntry;
    end;

    procedure SetEmplLedgEntry(NewEmplLedgEntry: Record "Employee Ledger Entry")
    begin
        Rec := NewEmplLedgEntry;
    end;

    procedure SetApplyingEmplLedgEntry()
    var
        Employee: Record Employee;
    begin
        case CalcType of
            CalcType::Direct:
                begin
                    if "Applying Entry" then begin
                        if TempApplyingEmplLedgEntry."Entry No." <> 0 then
                            EmplLedgEntry := TempApplyingEmplLedgEntry;
                        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
                        if "Applies-to ID" = '' then
                            SetEmplApplId;
                        CalcFields(Amount);
                        TempApplyingEmplLedgEntry := Rec;
                        if EmplLedgEntry."Entry No." <> 0 then begin
                            Rec := EmplLedgEntry;
                            "Applying Entry" := false;
                            SetEmplApplId;
                        end;
                        SetFilter("Entry No.", '<> %1', TempApplyingEmplLedgEntry."Entry No.");
                        ApplyingAmount := TempApplyingEmplLedgEntry."Remaining Amount";
                        ApplnDate := TempApplyingEmplLedgEntry."Posting Date";
                        ApplnCurrencyCode := TempApplyingEmplLedgEntry."Currency Code";
                    end;
                    CalcApplnAmount;
                end;
            CalcType::GenJnlLine:
                begin
                    TempApplyingEmplLedgEntry."Posting Date" := GenJnlLine."Posting Date";
                    TempApplyingEmplLedgEntry."Document Type" := GenJnlLine."Document Type";
                    TempApplyingEmplLedgEntry."Document No." := GenJnlLine."Document No.";
                    if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee then begin
                        TempApplyingEmplLedgEntry."Employee No." := GenJnlLine."Bal. Account No.";
                        Employee.Get(TempApplyingEmplLedgEntry."Employee No.");
                        TempApplyingEmplLedgEntry.Description := CopyStr(Employee.FullName, 1, MaxStrLen(TempApplyingEmplLedgEntry.Description));
                    end else begin
                        TempApplyingEmplLedgEntry."Employee No." := GenJnlLine."Account No.";
                        TempApplyingEmplLedgEntry.Description := GenJnlLine.Description;
                    end;
                    TempApplyingEmplLedgEntry."Currency Code" := GenJnlLine."Currency Code";
                    TempApplyingEmplLedgEntry.Amount := GenJnlLine.Amount;
                    TempApplyingEmplLedgEntry."Remaining Amount" := GenJnlLine.Amount;
                    CalcApplnAmount;
                end;
        end;
    end;

    procedure SetEmplApplId()
    begin
        if (CalcType = CalcType::GenJnlLine) and (TempApplyingEmplLedgEntry."Posting Date" < "Posting Date") then
            Error(
              EarlierPostingDateErr, TempApplyingEmplLedgEntry."Document Type", TempApplyingEmplLedgEntry."Document No.",
              "Document Type", "Document No.");

        if TempApplyingEmplLedgEntry."Entry No." <> 0 then
            GenJnlApply.CheckAgainstApplnCurrency(
              ApplnCurrencyCode, "Currency Code", GenJnlLine."Account Type"::Employee, true);

        EmplLedgEntry.Copy(Rec);
        CurrPage.SetSelectionFilter(EmplLedgEntry);

        if GenJnlLineApply then
            EmplEntrySetApplID.SetApplId(EmplLedgEntry, TempApplyingEmplLedgEntry, GenJnlLine."Applies-to ID")
        else
            EmplEntrySetApplID.SetApplId(EmplLedgEntry, TempApplyingEmplLedgEntry, '');

        ActionPerformed := EmplLedgEntry."Applies-to ID" <> '';
        CalcApplnAmount;
    end;

    local procedure CalcApplnAmount()
    begin
        AppliedAmount := 0;
        PmtDiscAmount := 0;
        DifferentCurrenciesInAppln := false;

        case CalcType of
            CalcType::Direct:
                begin
                    FindAmountRounding;
                    EmplEntryApplID := UserId;
                    if EmplEntryApplID = '' then
                        EmplEntryApplID := '***';

                    EmplLedgEntry := TempApplyingEmplLedgEntry;

                    AppliedEmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
                    AppliedEmplLedgEntry.SetRange("Employee No.", "Employee No.");
                    AppliedEmplLedgEntry.SetRange(Open, true);
                    if AppliesToID = '' then
                        AppliedEmplLedgEntry.SetRange("Applies-to ID", EmplEntryApplID)
                    else
                        AppliedEmplLedgEntry.SetRange("Applies-to ID", AppliesToID);

                    if TempApplyingEmplLedgEntry."Entry No." <> 0 then begin
                        EmplLedgEntry.CalcFields("Remaining Amount");
                        AppliedEmplLedgEntry.SetFilter("Entry No.", '<>%1', EmplLedgEntry."Entry No.");
                    end;

                    HandlChosenEntries(0, EmplLedgEntry."Remaining Amount");
                end;
            CalcType::GenJnlLine:
                begin
                    FindAmountRounding;
                    if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee then
                        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

                    case ApplnType of
                        ApplnType::"Applies-to Doc. No.":
                            begin
                                AppliedEmplLedgEntry := Rec;
                                with AppliedEmplLedgEntry do begin
                                    CalcFields("Remaining Amount");
                                    if "Currency Code" <> ApplnCurrencyCode then begin
                                        "Remaining Amount" :=
                                          CurrExchRate.ExchangeAmtFCYToFCY(
                                            ApplnDate, "Currency Code", ApplnCurrencyCode, "Remaining Amount");
                                        "Amount to Apply" :=
                                          CurrExchRate.ExchangeAmtFCYToFCY(
                                            ApplnDate, "Currency Code", ApplnCurrencyCode, "Amount to Apply");
                                    end;

                                    if "Amount to Apply" <> 0 then
                                        AppliedAmount := Round("Amount to Apply", AmountRoundingPrecision)
                                    else
                                        AppliedAmount := Round("Remaining Amount", AmountRoundingPrecision);

                                    if not DifferentCurrenciesInAppln then
                                        DifferentCurrenciesInAppln := ApplnCurrencyCode <> "Currency Code";
                                end;
                                CheckRounding;
                            end;
                        ApplnType::"Applies-to ID":
                            begin
                                GenJnlLine2 := GenJnlLine;
                                AppliedEmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
                                AppliedEmplLedgEntry.SetRange("Employee No.", GenJnlLine."Account No.");
                                AppliedEmplLedgEntry.SetRange(Open, true);
                                AppliedEmplLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");

                                HandlChosenEntries(1, GenJnlLine2.Amount);
                            end;
                    end;
                end;
        end;
    end;

    local procedure CalcApplnRemainingAmount(Amt: Decimal): Decimal
    var
        ApplnRemainingAmount: Decimal;
    begin
        ValidExchRate := true;
        if ApplnCurrencyCode = "Currency Code" then
            exit(Amt);

        if ApplnDate = 0D then
            ApplnDate := "Posting Date";
        ApplnRemainingAmount :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, "Currency Code", ApplnCurrencyCode, Amt, ValidExchRate);
        exit(ApplnRemainingAmount);
    end;

    local procedure CalcApplnAmounttoApply(AmounttoApply: Decimal): Decimal
    var
        ApplnAmountToApply: Decimal;
    begin
        ValidExchRate := true;

        if ApplnCurrencyCode = "Currency Code" then
            exit(AmounttoApply);

        if ApplnDate = 0D then
            ApplnDate := "Posting Date";
        ApplnAmountToApply :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, "Currency Code", ApplnCurrencyCode, AmounttoApply, ValidExchRate);
        exit(ApplnAmountToApply);
    end;

    local procedure FindAmountRounding()
    begin
        if ApplnCurrencyCode = '' then begin
            Currency.Init();
            Currency.Code := '';
            Currency.InitRoundingPrecision;
        end else
            if ApplnCurrencyCode <> Currency.Code then
                Currency.Get(ApplnCurrencyCode);

        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    local procedure CheckRounding()
    begin
        ApplnRounding := 0;

        case CalcType of
            CalcType::PurchHeader:
                exit;
            CalcType::GenJnlLine:
                if (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment) and
                   (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund)
                then
                    exit;
        end;

        if ApplnCurrencyCode = '' then
            ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision"
        else begin
            if ApplnCurrencyCode <> "Currency Code" then
                Currency.Get(ApplnCurrencyCode);
            ApplnRoundingPrecision := Currency."Appln. Rounding Precision";
        end;

        if (Abs((AppliedAmount - PmtDiscAmount) + ApplyingAmount) <= ApplnRoundingPrecision) and DifferentCurrenciesInAppln then
            ApplnRounding := -((AppliedAmount - PmtDiscAmount) + ApplyingAmount);
    end;

    procedure GetEmplLedgEntry(var EmplLedgEntry: Record "Employee Ledger Entry")
    begin
        EmplLedgEntry := Rec;
    end;

    local procedure FindApplyingEntry()
    begin
        if CalcType = CalcType::Direct then begin
            EmplEntryApplID := UserId;
            if EmplEntryApplID = '' then
                EmplEntryApplID := '***';

            EmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open);
            EmplLedgEntry.SetRange("Employee No.", "Employee No.");
            if AppliesToID = '' then
                EmplLedgEntry.SetRange("Applies-to ID", EmplEntryApplID)
            else
                EmplLedgEntry.SetRange("Applies-to ID", AppliesToID);
            EmplLedgEntry.SetRange(Open, true);
            EmplLedgEntry.SetRange("Applying Entry", true);
            if EmplLedgEntry.FindFirst then begin
                EmplLedgEntry.CalcFields(Amount, "Remaining Amount");
                TempApplyingEmplLedgEntry := EmplLedgEntry;
                SetFilter("Entry No.", '<>%1', EmplLedgEntry."Entry No.");
                ApplyingAmount := EmplLedgEntry."Remaining Amount";
                ApplnDate := EmplLedgEntry."Posting Date";
                ApplnCurrencyCode := EmplLedgEntry."Currency Code";
            end;
            CalcApplnAmount;
        end;
    end;

    local procedure AmounttoApplyOnAfterValidate()
    begin
        if ApplnType <> ApplnType::"Applies-to Doc. No." then begin
            CalcApplnAmount;
            CurrPage.Update(false);
        end;
    end;

    local procedure LookupOKOnPush()
    begin
        OK := true;
    end;

    local procedure PostDirectApplication(PreviewMode: Boolean)
    var
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
        PostApplication: Page "Post Application";
        ApplicationDate: Date;
        NewApplicationDate: Date;
        NewDocumentNo: Code[20];
    begin
        if CalcType = CalcType::Direct then begin
            if TempApplyingEmplLedgEntry."Entry No." <> 0 then begin
                Rec := TempApplyingEmplLedgEntry;
                ApplicationDate := EmplEntryApplyPostedEntries.GetApplicationDate(Rec);

                PostApplication.SetValues("Document No.", ApplicationDate);
                if ACTION::OK = PostApplication.RunModal then begin
                    PostApplication.GetValues(NewDocumentNo, NewApplicationDate);
                    if NewApplicationDate < ApplicationDate then
                        Error(ApplicationDateErr);
                end else
                    Error(ApplicationProcessCanceledErr);

                if PreviewMode then
                    EmplEntryApplyPostedEntries.PreviewApply(Rec, NewDocumentNo, NewApplicationDate)
                else
                    EmplEntryApplyPostedEntries.Apply(Rec, NewDocumentNo, NewApplicationDate);

                if not PreviewMode then begin
                    Message(ApplicationPostedMsg);
                    PostingDone := true;
                    CurrPage.Close;
                end;
            end else
                Error(MustSelectEntryErr);
        end else
            Error(PostingInWrongContextErr);
    end;

    local procedure CheckActionPerformed(): Boolean
    begin
        if ActionPerformed then
            exit(false);
        if (not (CalcType = CalcType::Direct) and not OK and not PostingDone) or
           (ApplnType = ApplnType::"Applies-to Doc. No.")
        then
            exit(false);
        exit(CalcType = CalcType::Direct);
    end;

    procedure SetAppliesToID(AppliesToID2: Code[50])
    begin
        AppliesToID := AppliesToID2;
    end;

    local procedure HandlChosenEntries(Type: Option Direct,GenJnlLine; CurrentAmount: Decimal)
    var
        TempAppliedEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        CorrectionAmount: Decimal;
        FromZeroGenJnl: Boolean;
    begin
        CorrectionAmount := 0;
        if AppliedEmplLedgEntry.FindSet(false, false) then begin
            repeat
                TempAppliedEmplLedgEntry := AppliedEmplLedgEntry;
                TempAppliedEmplLedgEntry.Insert();
            until AppliedEmplLedgEntry.Next = 0;
        end else
            exit;

        FromZeroGenJnl := (CurrentAmount = 0) and (Type = Type::GenJnlLine);

        repeat
            if not FromZeroGenJnl then
                TempAppliedEmplLedgEntry.SetRange(Positive, CurrentAmount < 0);
            if TempAppliedEmplLedgEntry.FindFirst then begin
                if ((CurrentAmount + TempAppliedEmplLedgEntry."Amount to Apply") * CurrentAmount) >= 0 then
                    AppliedAmount := AppliedAmount + CorrectionAmount;
                CurrentAmount := CurrentAmount + TempAppliedEmplLedgEntry."Amount to Apply";
            end else begin
                TempAppliedEmplLedgEntry.SetRange(Positive);
                TempAppliedEmplLedgEntry.FindFirst;
            end;

            AppliedAmount := AppliedAmount + TempAppliedEmplLedgEntry."Amount to Apply";

            TempAppliedEmplLedgEntry.Delete();
            TempAppliedEmplLedgEntry.SetRange(Positive);

        until not TempAppliedEmplLedgEntry.FindFirst;
        CheckRounding;
    end;
}

