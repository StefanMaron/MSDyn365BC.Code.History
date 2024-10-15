page 18664 "Update TDS Cert. Details"
{
    Caption = 'Update TDS Cert. Details';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Cust. Ledger Entry";
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
                field("Financial Year"; "Financial Year")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the financial year for which TDS certificate has been received.';
                }
                field("TDS Certificate Receivable"; "TDS Certificate Receivable")
                {
                    Editable = true;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the financial year for which TDS certificate has been received.';
                }
                field("TDS Certificate Received"; "TDS Certificate Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Mark in this field specify the same entry in the Rectify TDS Cert. Details window.';
                    trigger OnValidate()
                    begin
                        if "TDS Certificate Received" then
                            MARK := true
                        ELSE
                            MARK := false;
                    end;
                }
                field("TDS Section Code"; "TDS Section Code")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Choose the TDS section code from the lookup list for which TDS certificate has been received.';
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

    actions
    {
        area(processing)
        {
            action("Update TDS Cert. Details")
            {
                Caption = 'Update TDS Cert. Details';
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Select to open the Update TDS Cert. Details page.';
                Image = RefreshVATExemption;

                trigger OnAction()
                var
                    CustLedgerEntry: Record "Cust. Ledger Entry";
                begin
                    if Rec.FindSet() then
                        repeat
                            if Rec."TDS Certificate Received" then begin
                                CustLedgerEntry.Reset();
                                CustLedgerEntry.SetCurrentKey("Customer No.", "TDS Section Code", "Certificate No.", "TDS Certificate Received");
                                CustLedgerEntry.SetRange("Customer No.", CustNo);
                                CustLedgerEntry.SetRange("Certificate No.", CertNo);
                                if CustLedgerEntry.FindFirst() then
                                    if (CustLedgerEntry."TDS Certificate Rcpt Date" <> CertDate) or (CustLedgerEntry."TDS Certificate Amount" <> CertAmount) or
                                       (CustLedgerEntry."Financial Year" <> FinYear) or (CustLedgerEntry."TDS Section Code" <> TDSSection)
                                    then
                                        Error(CertificateDetailErr, CertNo);
                                CustLedgerEntry.Reset();
                                CustLedgerEntry.Get(Rec."Entry No.");
                                CustLedgerEntry."Certificate No." := CertNo;
                                CustLedgerEntry."TDS Certificate Rcpt Date" := CertDate;
                                CustLedgerEntry."TDS Certificate Amount" := CertAmount;
                                CustLedgerEntry."Financial Year" := FinYear;
                                CustLedgerEntry."TDS Section Code" := TDSSection;
                                CustLedgerEntry."Certificate Received" := true;
                                CustLedgerEntry.Modify()
                            end;
                        until Rec.Next() = 0;
                end;
            }
        }
    }

    trigger OnClosePage()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetCurrentKey("Customer No.", "TDS Section Code", "Certificate No.", "TDS Certificate Received");
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.SetFilter("Certificate No.", '%1', '');
        CustLedgerEntry.SetRange("TDS Certificate Received", true);
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry."TDS Certificate Received" := false;
                CustLedgerEntry."Certificate Received" := false;
                CustLedgerEntry.Modify();
            until (CustLedgerEntry.Next() = 0);
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Customer No.", CustNo);
        Rec.SetRange("TDS Certificate Receivable", TRUE);
        Rec.SetRange("Certificate Received", FALSE);
        Rec.FilterGroup(0);
    end;

    procedure SetCertificateDetail(CertificateNo: Code[20]; CertificateDate: Date; CustomerNo: Code[20]; CertificateAmount: Decimal; FinancialYear: Integer; TDSSectioncode: Code[10])
    begin
        CertNo := CertificateNo;
        CertDate := CertificateDate;
        CustNo := CustomerNo;
        CertAmount := CertificateAmount;
        FinYear := FinancialYear;
        TDSSection := TDSSectioncode;
    end;

    var
        CertNo: Code[20];
        CertDate: Date;
        CustNo: Code[20];
        CertAmount: Decimal;
        FinYear: Integer;
        TDSSection: Code[10];
        CertificateDetailErr: Label 'Certificate Details for Certificate No. %1 should be same as entered earlier.', Comment = '%1 = Certificate No.';
}