#if not CLEAN21
page 2137 "O365 Bank Information Settings"
{
    Caption = 'Bank Information';
    DeleteAllowed = false;
    SourceTable = "Company Information";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group("Specify your company's bank information.")
            {
                Caption = 'Specify your company''s bank information.';
                InstructionalText = 'This information is included on invoices that you send to customers to inform about payments to your bank account.';
                field("Bank Name"; Rec."Bank Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the bank the company uses.';
                }
                field("Bank Branch No."; Rec."Bank Branch No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the bank branch.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Initialize();
    end;

    trigger OnModifyRecord(): Boolean
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.Get(CompanyInformationMgt.GetCompanyBankAccount()) then begin
            BankAccount.Validate(Name, "Bank Name");
            BankAccount.Validate("Bank Branch No.", "Bank Branch No.");
            BankAccount.Validate("Bank Account No.", "Bank Account No.");
            BankAccount.Modify(true);
        end;
    end;

    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";

    local procedure Initialize()
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}
#endif
