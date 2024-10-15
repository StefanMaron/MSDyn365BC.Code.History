codeunit 7000008 "Document-Edit"
{
    Permissions = TableData "Cartera Doc." = imd,
                  TableData "Cust. Ledger Entry" = m,
                  TableData "Vendor Ledger Entry" = m,
                  TableData "Detailed Cust. Ledg. Entry" = m,
                  TableData "Detailed Vendor Ledg. Entry" = m;
    TableNo = "Cartera Doc.";

    trigger OnRun()
    begin
        CarteraDoc := Rec;
        CarteraDoc.LockTable();
        CarteraDoc.Find;
        CarteraDoc."Category Code" := "Category Code";
        CarteraDoc."Direct Debit Mandate ID" := "Direct Debit Mandate ID";
        if "Bill Gr./Pmt. Order No." = '' then begin
            CarteraDoc."Due Date" := "Due Date";
            CarteraDoc."Cust./Vendor Bank Acc. Code" := "Cust./Vendor Bank Acc. Code";
#if not CLEAN22
            CarteraDoc."Pmt. Address Code" := "Pmt. Address Code";
#endif
            CarteraDoc."Collection Agent" := "Collection Agent";
            CarteraDoc.Accepted := Accepted;
        end;
        OnBeforeModifyCarteraDoc(CarteraDoc, Rec);
        CarteraDoc.Modify();
        Rec := CarteraDoc;
    end;

    var
        CarteraDoc: Record "Cartera Doc.";

    [Scope('OnPrem')]
    procedure EditDueDate(CarteraDoc: Record "Cartera Doc.")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with CarteraDoc do
            case Type of
                Type::Receivable:
                    begin
                        CustLedgEntry.Get("Entry No.");
                        CustLedgEntry."Due Date" := "Due Date";
                        CustLedgEntry.Modify();
                        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Posting Date");
                        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
                        DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", "Due Date");
                    end;
                Type::Payable:
                    begin
                        VendLedgEntry.Get("Entry No.");
                        VendLedgEntry."Due Date" := "Due Date";
                        VendLedgEntry.Modify();
                        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Posting Date");
                        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                        DtldVendLedgEntry.ModifyAll("Initial Entry Due Date", "Due Date");
                    end;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyCarteraDoc(var CarteraDoc: Record "Cartera Doc."; CurrCarteraDoc: Record "Cartera Doc.")
    begin
    end;
}

