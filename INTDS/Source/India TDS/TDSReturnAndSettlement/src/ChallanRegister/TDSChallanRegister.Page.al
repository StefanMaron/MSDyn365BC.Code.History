page 18752 "TDS Challan Register"
{
    Caption = 'TDS Challan Register';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "TDS Challan Register";
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Quarter; Quarter)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quarter this accounting period belongs to.';
                }
                field("Financial Year"; "Financial Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the accounting period.';
                }
                field("Challan No."; "Challan No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan number provided by the bank while depositing the TDS amount.';
                }
                field("Challan Date"; "Challan Date")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan date on which TDS is paid to government.';
                }
                field("BSR Code"; "BSR Code")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Basic Statistical Return Code provided by the bank while depositing the TDS amount.';
                }
                field("Minor Head Code"; "Minor Head Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minor head used in the payment.';
                }
                field("Paid By Book Entry"; "Paid By Book Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Select this field to specify that challan has been paid by book entry.';
                }
                field("Transfer Voucher No."; "Transfer Voucher No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transfer voucher reference.';
                }
                field("TDS Interest Amount"; "TDS Interest Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of interest payable.';
                }
                field("TDS Others"; "TDS Others")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of other charges payable.';
                }
                field("TDS Fee"; "TDS Fee")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of fees payable.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Update Challan Register")
            {
                Caption = 'Update Challan Register';
                Image = UpdateDescription;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Select this to update the details like Interest Amount, Others and Paid by Book entry in TDS challan register during the financial year.';
                trigger OnAction()
                var
                    UpdateChallanRegister: Report "Update Challan Register";
                begin
                    if (not Filed) and (not Revised) or "Correction-C9" then begin
                        UpdateChallanRegister.UpdateChallan("TDS Interest Amount", "TDS Others", "TDS Fee", "Entry No.");
                        UpdateChallanRegister.Run();
                    end;
                end;
            }
        }
    }
}

