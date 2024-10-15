page 18753 "Update TDS Register"
{
    Caption = 'Update TDS Register';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;
    SourceTable = "TDS Entry";
    SourceTableView = WHERE("TDS Paid" = CONST(true),
                             "Total TDS Including SHE CESS" = FILTER(<> 0));

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Posting Date"; "Posting Date")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that the entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number for the entry .';
                }
                field("Pay TDS Document No."; "Pay TDS Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the TDS entry to be paid to government.';
                }
                field("TDS Base Amount"; "TDS Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that is used as base to calculate TDS on the TDS entry.';
                }
                field("TDS %"; "TDS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Species the TDS % on the TDS entry.';
                }
                field("TDS Amount"; "TDS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TDS amount on the TDS entry.';
                }
                field("Surcharge %"; "Surcharge %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge % on the TDS entry.';
                }
                field("Surcharge Amount"; "Surcharge Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge amount on TDS entry.';
                }
                field("TDS Amount Including Surcharge"; "TDS Amount Including Surcharge")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of TDS amount and surcharge amount on the TDS entry.';
                }
                field("eCESS %"; "eCESS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess % on the TDS entry.';
                }
                field("eCESS Amount"; "eCESS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess amount on the TDS entry.';
                }
                field("SHE Cess %"; "SHE Cess %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % on the TDS entry.';
                }
                field("SHE Cess Amount"; "SHE Cess Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess amount on the TDS entry.';
                }
                field("Total TDS Including SHE CESS"; "Total TDS Including SHE CESS")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of TDS amount, surcharge amount, eCess and SHE Cess amount on the TDS entry.';
                }
                field(Adjusted; Adjusted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the TDS entry is adjusted.';
                }
                field("Bal. TDS Including SHE CESS"; "Bal. TDS Including SHE CESS")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of TDS including SHE CESS amount.';
                }
                field("Challan Date"; "Challan Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan date for the TDS entry once TDS amount is paid to government.';
                }
                field("Challan No."; "Challan No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the challan number for the TDS entry once TDS amount is paid to government.';
                }
                field("BSR Code"; "BSR Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Basic Statistical Return Code provided by the bank while depositing the TDS amount.';
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where TDS amount has been deposited.';
                }
                field("Minor Head Code"; "Minor Head Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minor head code used for the payment.';
                }
                field("Nature of Remittance"; "Nature of Remittance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the type of Remittance deductee deals with for which the entry has been created.';
                }
                field("Act Applicable"; "Act Applicable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether tax rates are applicable under IT act or DTAA.';
                }
                field("Country Code"; "Country Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country code used for the transaction.';
                }
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the check through which payment has been made.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Update Challan Details")
            {
                Caption = 'Update Challan Details';
                Image = RefreshRegister;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Select this to update the details like Challan No, BSR code, Bank Name, Cheque No. etc. on individual transactions in the Update TDS register.';
                trigger OnAction()
                var
                    UpdateChallanDetails: Report "Update Challan Details";
                begin
                    UpdateChallanDetails.SetDocumentNo("Pay TDS Document No.");
                    UpdateChallanDetails.Run();
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    var
        TDSDeleteErr: Label 'You cannot delete TDS entries.';
    begin
        Error(TDSDeleteErr);
    end;

    procedure SetDocumentNo(DocumentNo: Code[20])
    begin
        "Pay TDS Document No." := DocumentNo;
    end;
}

