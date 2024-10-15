page 18666 "Rectify TDS Cert. Details"
{
    Caption = 'Rectify TDS Cert. Details';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Cust. Ledger Entry";
    SourceTableView = WHERE("TDS Certificate Receivable" = filter(true),
                            "TDS Certificate Received" = filter(true));

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; "Entry No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, when the entry was created.';
                }
                field("Customer No."; "Customer No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the customer number from whom TDS certificate is received.';
                }
                field("Posting Date"; "Posting Date")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the posting date of the customer ledger entry.';
                }
                field("Document Type"; "Document Type")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document of the customer ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the customer ledger entry.';
                }
                field(Amount; Amount)
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the customer ledger entry.';
                }
                field("TDS Certificate Received"; "TDS Certificate Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Mark in this field specify the same entry in the Rectify TDS Cert. Details window.';
                    trigger OnValidate()
                    begin
                        if "TDS Certificate Received" AND ("Certificate No." = '') then
                            ERROR(EmptyCertificateDetailsErr);
                        if "TDS Certificate Received" then begin
                            "Certificate Received" := TRUE;
                            Modify();
                        END;
                    end;
                }
                field("Financial Year"; "Financial Year")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the financial year for which TDS certificate has received.';
                }
                field("TDS Section Code"; "TDS Section Code")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Choose the TDS section code from the lookup list for which TDS certificate has received.';
                }
                field("Certificate No."; "Certificate No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the certificate number as per the certificate received.';
                }
                field("TDS Certificate Rcpt Date"; "TDS Certificate Rcpt Date")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which TDS certificate has been received.';
                }
                field("TDS Certificate Amount"; "TDS Certificate Amount")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the TDS certificate amount as per the TDS certificate.';
                }
            }
        }
    }
    var
        EmptyCertificateDetailsErr: Label 'Certificate Received cannot be True as Certificate details are not filled up.';
}

