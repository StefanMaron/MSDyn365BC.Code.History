codeunit 338 "VAT Entry - Edit"
{
    Permissions = TableData "VAT Entry" = m;
    TableNo = "VAT Entry";

    trigger OnRun()
    begin
        VATEntry := Rec;
        VATEntry.LockTable();
        VATEntry.Find();
        VATEntry.Validate(Type);
        VATEntry."VAT Reporting Date" := "VAT Reporting Date";
        VATEntry."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
        VATEntry."Ship-to/Order Address Code" := "Ship-to/Order Address Code";
        VATEntry."EU 3-Party Trade" := "EU 3-Party Trade";
        VATEntry."Country/Region Code" := "Country/Region Code";
        VATEntry."VAT Registration No." := "VAT Registration No.";
        OnBeforeVATEntryModify(VATEntry, Rec);
        VATEntry.TestField("Entry No.", "Entry No.");
        VATEntry.Modify();
        Rec := VATEntry;
    end;

    var
        VATEntry: Record "VAT Entry";

    procedure SetGLAccountNo(var VATEntryModify: Record "VAT Entry"; GLAccountNo: Code[20])
    begin
        VATEntryModify."G/L Acc. No." := GLAccountNo;
        VATEntryModify.Modify();
    end;

    procedure SetGLAccountNo(VATEntryNo: Integer; GLAccountNo: Code[20])
    begin
        VATEntry.SetRange("Entry No.", VATEntryNo);
        VATEntry.ModifyAll("G/L Acc. No.", GLAccountNo, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATEntryModify(var VATEntry: Record "VAT Entry"; FromVATEntry: Record "VAT Entry")
    begin
    end;
}

