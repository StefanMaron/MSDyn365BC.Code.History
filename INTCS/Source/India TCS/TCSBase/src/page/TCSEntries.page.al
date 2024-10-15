page 18810 "TCS Entries"
{
    Caption = 'TCS Entries';
    Editable = false;
    PageType = List;
    SourceTable = "TCS Entry";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies type of the account on TCS entry.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer account on the TCS entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the TCS entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that the TCS entry is linked to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the TCS entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the TCS entry.';
                }
                field("TCS Base Amount"; "TCS Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount on which TCS is calculated.';
                }
                field("TCS Amount Including Surcharge"; "TCS Amount Including Surcharge")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of TCS amount and surcharge amount on the TCS entry.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number of the customer account on the TCS entry.';
                }
                field("Assessee Code"; "Assessee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the assessee code of the customer account on TCS entry.';
                }
                field("TCS Nature of Collection"; "TCS Nature of Collection")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Nature of Collection of TCS entry.';
                }
                field("TCS %"; "TCS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TCS % on the TCS entry.';
                }
                field("TCS Amount"; "TCS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TCS amount on the TCS entry.';
                }
                field("Surcharge %"; "Surcharge %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge % on the TCS entry.';
                }
                field("Surcharge Amount"; "Surcharge Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge amount on the TCS entry.';
                }
                field("eCESS %"; "eCESS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess % on TCS entry.';
                }
                field("eCESS Amount"; "eCESS Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess amount on TCS entry.';
                }
                field("SHE Cess %"; "SHE Cess %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % on TCS entry.';
                }
                field("SHE Cess Amount"; "SHE Cess Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess amount on TCS entry.';
                }
                field("Concessional Code"; "Concessional Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied concessional code on the TCS entry.';
                }
                field("T.C.A.N. No."; "T.C.A.N. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the T.C.A.N. number on the TCS entry.';
                }
                field("Customer Account No."; "Customer Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies account number of the customer on the TCS entry.';
                }
                field("Transaction No."; "Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Customer P.A.N. No."; "Customer P.A.N. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies PAN number of the customer on the TCS entry.';
                }
                field("Total TCS Including SHE CESS"; "Total TCS Including SHE CESS")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of TCS amount, surcharge amount, eCess and SHE Cess amount on the TCS entry.';
                }
                field("Pay TCS Document No."; "Pay TCS Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the TCS entry to be paid to government.';
                }
                field("TCS Paid"; "TCS Paid")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the amount on TCS entry is fully paid.';
                }
                field("Challan Date"; "Challan Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated once TCS is paid to government and relevant details to be updated in TCS register.';
                }
                field("Challan No."; "Challan No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated once TCS is paid to government and relevant details to be updated in TCS register.';
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated once TCS made to government and relevant details to be updated in TCS register.';
                }
                field(Adjusted; Adjusted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated if any transaction is adjusted using TCS adjustment Journal.';
                }
                field("Adjusted TCS %"; "Adjusted TCS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the % on which transaction is adjusted using TCS adjustment Journal.';
                }
                field("Bal. TCS Including SHE CESS"; "Bal. TCS Including SHE CESS")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance TDS/TCS including SHE Cess on the adjustment journal line.';
                }
                field("Invoice Amount"; "Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays the amount of the transaction document.';
                }
                field(Applied; Applied)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays if transaction is applied to any transaction.';
                }
                field("Adjusted Surcharge %"; "Adjusted Surcharge %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated if any transaction is adjusted using TCS adjustment Journal.';
                }
                field("Surcharge Base Amount"; "Surcharge Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount on which surcharge is being calculated.';
                }
                field("Adjusted eCESS %"; "Adjusted eCESS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated if any transaction is adjusted using TCS adjustment Journal.';
                }
                field("Adjusted SHE CESS %"; "Adjusted SHE CESS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated if any transaction is adjusted using TCS adjustment Journal.';
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the TCS entry is reversed.';
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies reversal entry number.';
                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies reversed entry number.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID of the user who has posted the transaction.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code. Source code can be PURCHASES, SALES, GENJNL, BANKPYMT etc.';
                }
                field("Check/DD No."; "Check/DD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated once TCS is paid to government and relevant details has to be updated in TCS register.';
                }
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field will be updated once TCS is paid to government and relevant details to be updated in TCS register.';
                }
                field("TCS Payment Date"; "TCS Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which TCS is paid to government.';
                }
                field("Challan Register Entry No."; "Challan Register Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of challan details of the transactions.';
                }
                field("Concessional Form No."; "Concessional Form No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied concessional form no. on the TCS entry.';
                }
            }
        }
    }
}

