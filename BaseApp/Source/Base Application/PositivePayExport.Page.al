page 1233 "Positive Pay Export"
{
    Caption = 'Positive Pay Export';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    ShowFilter = false;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(LastUploadDateEntered; LastUploadDateEntered)
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Upload Date';
                    ToolTip = 'Specifies the day when a positive pay file was last exported.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm;
                    end;
                }
                field(LastUploadTime; LastUploadTime)
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Upload Time';
                    Editable = false;
                    ToolTip = 'Specifies the time when a positive pay file was last exported.';
                }
                field(CutoffUploadDate; CutoffUploadDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cutoff Upload Date';
                    ToolTip = 'Specifies a date before which payments are not included in the exported file.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm;
                    end;
                }
                field(BankPaymentType; BankPaymentType) 
                {
                    ApplicationArea = Suite;
                    Caption = 'Bank Payment Type';
                    ToolTip = 'Specifies the type of bank payment to include in a positive pay file that you can submit to your bank. For example, this is useful if your bank allows the file to include only check payments.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm();
                    end;
                }       
            }
            part(PosPayExportDetail; "Positive Pay Export Detail")
            {
                ApplicationArea = Suite;
                Caption = 'Positive Pay Export Detail';
                SubPageLink = "Bank Account No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Export)
            {
                ApplicationArea = Suite;
                Caption = 'Export';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Export Positive Pay data to a file that you can send to the bank when processing payments to make sure that the bank only clears validated checks and amounts.';

                trigger OnAction()
                var
                    CheckLedgerEntry: Record "Check Ledger Entry";
                begin
                    CheckLedgerEntry.SetCurrentKey("Bank Account No.", "Check Date");
                    CheckLedgerEntry.SetRange("Bank Account No.", "No.");
                    CheckLedgerEntry.SetRange("Check Date", LastUploadDateEntered, CutoffUploadDate);
                    if BankPaymentType <> Enum::"Bank Payment Type"::" " then
                        CheckLedgerEntry.SetRange("Bank Payment Type", BankPaymentType);
                    CheckLedgerEntry.ExportCheckFile();
                    UpdateSubForm();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm;
    end;

    trigger OnOpenPage()
    begin
        PositivePayEntry.SetRange("Bank Account No.", "No.");
        if PositivePayEntry.FindLast() then begin
            LastUploadDateEntered := DT2Date(PositivePayEntry."Upload Date-Time");
            LastUploadTime := DT2Time(PositivePayEntry."Upload Date-Time");
        end;
        CutoffUploadDate := WorkDate;
        UpdateSubForm;
    end;

    var
        PositivePayEntry: Record "Positive Pay Entry";
        BankPaymentType: Enum "Bank Payment Type";
        LastUploadDateEntered: Date;
        LastUploadTime: Time;
        CutoffUploadDate: Date;

    [Scope('OnPrem')]
    procedure UpdateSubForm()
    begin
        CurrPage.PosPayExportDetail.PAGE.Set(LastUploadDateEntered, CutoffUploadDate, "No.");
        CurrPage.PosPayExportDetail.PAGE.SetBankPaymentType(BankPaymentType);
    end;
}

