page 2137 "O365 Bank Information Settings"
{
    Caption = 'Bank Information';
    DeleteAllowed = false;
    SourceTable = "Company Information";

    layout
    {
        area(content)
        {
            group("Specify your company's bank information.")
            {
                Caption = 'Specify your company''s bank information.';
                InstructionalText = 'This information is included on invoices that you send to customers to inform about payments to your bank account.';
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the bank the company uses.';
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the bank branch.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
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
        Initialize;
    end;

    trigger OnModifyRecord(): Boolean
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.Get(CompanyInformationMgt.GetCompanyBankAccount) then begin
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
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

