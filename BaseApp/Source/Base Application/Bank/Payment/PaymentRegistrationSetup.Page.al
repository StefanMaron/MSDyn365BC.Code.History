namespace Microsoft.Bank.Payment;

page 982 "Payment Registration Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Registration Setup';
    DataCaptionExpression = PageCaptionVariable;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Payment Registration Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                InstructionalText = 'Select which balancing account you want to register the payment to, as well as which journal template to use.';
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template that the Payment Registration window is based on.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch that the Payment Registration window is based on.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balancing Account Type';
                    ToolTip = 'Specifies the type of account that is used as the balancing account for payments. The field is filled according to the selection in the Journal Batch Name field.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balancing Account';
                    ToolTip = 'Specifies the account number that is used as the balancing account for payments.';
                }
                field("Use this Account as Def."; Rec."Use this Account as Def.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use this Account as Default';
                    ToolTip = 'Specifies if the account in the Bal. Account No. field is used for all payments.';
                }
                field("Auto Fill Date Received"; Rec."Auto Fill Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Automatically Fill Date Received';
                    ToolTip = 'Specifies if the Date Received and the Amount Received fields are automatically filled when you select the Payment Made check box.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get(UserId()) then begin
            if Rec.Get() then;

            Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
            Rec.Insert();
        end;

        PageCaptionVariable := '';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            exit(Rec.ValidateMandatoryFields(true));
    end;

    var
        PageCaptionVariable: Text[10];
}

