page 1269 "Auto. Bank Stmt. Import Setup"
{
    Caption = 'Automatic Bank Statement Import Setup';
    PageType = StandardDialog;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            field("Transaction Import Timespan"; "Transaction Import Timespan")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Number of Days Included';
                ToolTip = 'Specifies how far back in time to get new bank transactions for.';

                trigger OnValidate()
                begin
                    if not ("Transaction Import Timespan" in [0 .. 9999]) then begin
                        "Transaction Import Timespan" := xRec."Transaction Import Timespan";
                        Message(TransactionImportTimespanMustBePositiveMsg);
                    end;
                end;
            }
            field("Automatic Stmt. Import Enabled"; "Automatic Stmt. Import Enabled")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enabled';
                ToolTip = 'Specifies that the service is enabled.';
            }
        }
    }

    actions
    {
    }

    var
        TransactionImportTimespanMustBePositiveMsg: Label 'The value in the Number of Days Included field must be a positive number not greater than 9999.';
}

