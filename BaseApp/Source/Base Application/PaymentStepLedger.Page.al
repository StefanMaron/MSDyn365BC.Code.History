page 10874 "Payment Step Ledger"
{
    Caption = 'Payment Step Ledger';
    PageType = Card;
    SourceTable = "Payment Step Ledger";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Payment Class"; "Payment Class")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the payment class.';
                }
                field(Line; Line)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the ledger line''s entry number.';
                }
                field(Sign; Sign)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = SignEnable;
                    ToolTip = ' Specifies if the posting will result in a debit or credit entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used on the general ledger entry.';
                }
                field("Accounting Type"; "Accounting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AccountingTypeEnable;
                    ToolTip = 'Specifies the type of account to post the entry to.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AccountTypeEnable;
                    ToolTip = 'Specifies the type of account to post the entry to.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AccountNoEnable;
                    ToolTip = 'Specifies the account number to post the entry to.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field("Customer Posting Group"; "Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = CustomerPostingGroupEnable;
                    ToolTip = 'Specifies a code for the customer posting group used when the entry is posted.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = VendorPostingGroupEnable;
                    ToolTip = 'Specifies a code for the vendor posting group used when the entry is posted.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field(Root; Root)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = RootEnable;
                    ToolTip = 'Specifies the root for the G/L accounts group used, when you have selected either G/L Account / Month, or G/L Account / Week.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field("Memorize Entry"; "Memorize Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that entries created in this step will be memorized, so the next application can be performed against newly posted entries.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field(Application; Application)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ApplicationEnable;
                    ToolTip = 'Specifies how to apply entries.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field("Detail Level"; "Detail Level")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = DetailLevelEnable;
                    ToolTip = 'Specifies how payment lines will be posted.';

                    trigger OnValidate()
                    begin
                        DisableFields;
                    end;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that will be assigned to the ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method to assign a document number to the ledger entry.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DisableFields;
    end;

    trigger OnInit()
    begin
        DetailLevelEnable := true;
        RootEnable := true;
        VendorPostingGroupEnable := true;
        CustomerPostingGroupEnable := true;
        AccountNoEnable := true;
        AccountTypeEnable := true;
        ApplicationEnable := true;
        SignEnable := true;
        AccountingTypeEnable := true;
    end;

    var
        [InDataSet]
        AccountingTypeEnable: Boolean;
        [InDataSet]
        SignEnable: Boolean;
        [InDataSet]
        ApplicationEnable: Boolean;
        [InDataSet]
        AccountTypeEnable: Boolean;
        [InDataSet]
        AccountNoEnable: Boolean;
        [InDataSet]
        CustomerPostingGroupEnable: Boolean;
        [InDataSet]
        VendorPostingGroupEnable: Boolean;
        [InDataSet]
        RootEnable: Boolean;
        [InDataSet]
        DetailLevelEnable: Boolean;

    [Scope('OnPrem')]
    procedure DisableFields()
    begin
        AccountingTypeEnable := true;
        SignEnable := true;
        ApplicationEnable := true;
        if "Accounting Type" = "Accounting Type"::"Setup Account" then begin
            AccountTypeEnable := true;
            AccountNoEnable := true;
            if "Account Type" = "Account Type"::Customer then begin
                CustomerPostingGroupEnable := true;
                VendorPostingGroupEnable := false;
            end else
                if "Account Type" = "Account Type"::Vendor then begin
                    CustomerPostingGroupEnable := false;
                    VendorPostingGroupEnable := true;
                end else begin
                    CustomerPostingGroupEnable := false;
                    VendorPostingGroupEnable := false;
                end;
            RootEnable := false;
        end else begin
            AccountTypeEnable := false;
            AccountNoEnable := false;
            if "Accounting Type" in ["Accounting Type"::"G/L Account / Month", "Accounting Type"::"G/L Account / Week"] then begin
                RootEnable := true;
                CustomerPostingGroupEnable := false;
                VendorPostingGroupEnable := false;
            end else begin
                RootEnable := false;
                CustomerPostingGroupEnable := true;
                VendorPostingGroupEnable := true;
            end;
        end;
        if "Accounting Type" = "Accounting Type"::"Bal. Account Previous Entry" then begin
            CustomerPostingGroupEnable := false;
            VendorPostingGroupEnable := false;
        end;
        if "Memorize Entry" or (Application <> Application::None) then begin
            "Detail Level" := "Detail Level"::Line;
            DetailLevelEnable := false;
        end else
            DetailLevelEnable := true;
    end;
}

