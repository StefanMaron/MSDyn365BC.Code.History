page 1702 "Deferral Schedule"
{
    Caption = 'Deferral Schedule';
    DataCaptionFields = "Start Date";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    ShowFilter = false;
    SourceTable = "Deferral Header";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Amount to Defer"; "Amount to Defer")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount to defer per period.';
                }
                field("Calc. Method"; "Calc. Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the Amount field for each period is calculated. Straight-Line: Calculated per the number of periods, distributed by period length. Equal Per Period: Calculated per the number of periods, distributed evenly on periods. Days Per Period: Calculated per the number of days in the period. User-Defined: Not calculated. You must manually fill the Amount field for each period.';
                }
                field("No. of Periods"; "No. of Periods")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many accounting periods the total amounts will be deferred to.';
                }
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the source document.';
                }
                field(StartDateCalcMethod; StartDateCalcMethod)
                {
                    ApplicationArea = Suite;
                    Caption = 'Start Date Calc. Method';
                    Editable = false;
                    ToolTip = 'Specifies the method used to calculate the start date that is used for calculating deferral amounts.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when to start calculating deferral amounts.';
                }
            }
            part(DeferralSheduleSubform; "Deferral Schedule Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Deferral Doc. Type" = FIELD("Deferral Doc. Type"),
                              "Gen. Jnl. Template Name" = FIELD("Gen. Jnl. Template Name"),
                              "Gen. Jnl. Batch Name" = FIELD("Gen. Jnl. Batch Name"),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Actions")
            {
                Caption = 'Actions';
                action(CalculateSchedule)
                {
                    ApplicationArea = Suite;
                    Caption = 'Calculate Schedule';
                    Image = CalculateCalendar;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Calculate the deferral schedule by which revenue or expense amounts will be distributed over multiple accounting periods.';

                    trigger OnAction()
                    begin
                        Changed := CalculateSchedule;
                    end;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        Changed := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Changed := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Changed := true;
    end;

    trigger OnOpenPage()
    begin
        InitForm;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralUtilities: Codeunit "Deferral Utilities";
        EarliestPostingDate: Date;
        RecCount: Integer;
        ExpectedCount: Integer;
    begin
        // Prevent closing of the window if the sum of the periods does not equal the Amount to Defer
        if DeferralHeader.Get("Deferral Doc. Type",
             "Gen. Jnl. Template Name",
             "Gen. Jnl. Batch Name",
             "Document Type",
             "Document No.", "Line No.")
        then begin
            CalcFields("Schedule Line Total");
            if "Schedule Line Total" <> DeferralHeader."Amount to Defer" then
                Error(TotalToDeferErr);
        end;

        DeferralLine.SetRange("Deferral Doc. Type", "Deferral Doc. Type");
        DeferralLine.SetRange("Gen. Jnl. Template Name", "Gen. Jnl. Template Name");
        DeferralLine.SetRange("Gen. Jnl. Batch Name", "Gen. Jnl. Batch Name");
        DeferralLine.SetRange("Document Type", "Document Type");
        DeferralLine.SetRange("Document No.", "Document No.");
        DeferralLine.SetRange("Line No.", "Line No.");

        RecCount := DeferralLine.Count();
        ExpectedCount := DeferralUtilities.CalcDeferralNoOfPeriods("Calc. Method", "No. of Periods", "Start Date");
        if ExpectedCount <> RecCount then
            FieldError("No. of Periods");

        DeferralLine.SetFilter("Posting Date", '>%1', 0D);
        if DeferralLine.FindFirst then begin
            EarliestPostingDate := DeferralLine."Posting Date";
            if EarliestPostingDate <> DeferralHeader."Start Date" then
                Error(PostingDateErr);
        end;
    end;

    var
        TotalToDeferErr: Label 'The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.';
        Changed: Boolean;
        DisplayDeferralDocType: Option Purchase,Sales,"G/L";
        DisplayGenJnlTemplateName: Code[10];
        DisplayGenJnlBatchName: Code[10];
        DisplayDocumentType: Integer;
        DisplayDocumentNo: Code[20];
        DisplayLineNo: Integer;
        PostingDateErr: Label 'You cannot specify a posting date that is not equal to the start date.';
        PostingDate: Date;
        StartDateCalcMethod: Text;

    procedure SetParameter(DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    begin
        DisplayDeferralDocType := DeferralDocType;
        DisplayGenJnlTemplateName := GenJnlTemplateName;
        DisplayGenJnlBatchName := GenJnlBatchName;
        DisplayDocumentType := DocumentType;
        DisplayDocumentNo := DocumentNo;
        DisplayLineNo := LineNo;
    end;

    [Scope('OnPrem')]
    procedure GetParameter(): Boolean
    begin
        exit(Changed or CurrPage.DeferralSheduleSubform.PAGE.GetChanged)
    end;

    procedure InitForm()
    var
        DeferralTemplate: Record "Deferral Template";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        Get(DisplayDeferralDocType, DisplayGenJnlTemplateName, DisplayGenJnlBatchName, DisplayDocumentType, DisplayDocumentNo, DisplayLineNo);

        DeferralTemplate.Get("Deferral Code");
        StartDateCalcMethod := Format(DeferralTemplate."Start Date");
        case DisplayDeferralDocType of
            "Deferral Doc. Type"::"G/L":
                begin
                    GenJournalLine.Get(DisplayGenJnlTemplateName, DisplayGenJnlBatchName, DisplayLineNo);
                    PostingDate := GenJournalLine."Posting Date";
                end;
            "Deferral Doc. Type"::Sales:
                begin
                    SalesHeader.Get(DisplayDocumentType, DisplayDocumentNo);
                    PostingDate := SalesHeader."Posting Date";
                end;
            "Deferral Doc. Type"::Purchase:
                begin
                    PurchaseHeader.Get(DisplayDocumentType, DisplayDocumentNo);
                    PostingDate := PurchaseHeader."Posting Date";
                end;
        end;
    end;
}

