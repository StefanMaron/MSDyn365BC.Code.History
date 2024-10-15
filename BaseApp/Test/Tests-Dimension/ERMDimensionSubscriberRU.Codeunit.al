codeunit 143017 "ERM Dimension Subscriber - RU"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryDim: Codeunit "Library - Dimension";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnGetLocalTablesWithDimSetIDValidationIgnored', '', false, false)]
    local procedure GetCountOfLocalTablesWithDimSetIDValidationIgnored(var CountOfTablesIgnored: Integer)
    begin
        // Specifies how many tables with "Dimension Set ID" field related to "Dimension Set Entry" table should not have OnValidate trigger which updates shortcut dimensions

        CountOfTablesIgnored += 18;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnVerifyShorcutDimCodesUpdatedOnDimSetIDValidationLocal', '', false, false)]
    local procedure VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(var TempAllObj: Record AllObj temporary; DimSetID: Integer; GlobalDim1ValueCode: Code[20]; GlobalDim2ValueCode: Code[20])
    var
        FADocumentHeader: Record "FA Document Header";
        FADocumentLine: Record "FA Document Line";
        VATAllocationLine: Record "VAT Allocation Line";
        DefaultVATAllocationLine: Record "Default VAT Allocation Line";
        TaxDiffJournalLine: Record "Tax Diff. Journal Line";
        EmployeeJournalLine: Record "Employee Journal Line";
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
        PayrollDocument: Record "Payroll Document";
        PayrollDocumentLine: Record "Payroll Document Line";
    begin
        // Verifies local tables with "Dimension Set ID" field related to "Dimension Set Entry" and OnValidate trigger which updates shortcut dimensions

        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, FADocumentHeader, FADocumentHeader.FieldNo("Dimension Set ID"),
          FADocumentHeader.FieldNo("Shortcut Dimension 1 Code"), FADocumentHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, FADocumentLine, FADocumentLine.FieldNo("Dimension Set ID"),
          FADocumentLine.FieldNo("Shortcut Dimension 1 Code"), FADocumentLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, VATAllocationLine, VATAllocationLine.FieldNo("Dimension Set ID"),
          VATAllocationLine.FieldNo("Shortcut Dimension 1 Code"), VATAllocationLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, DefaultVATAllocationLine, DefaultVATAllocationLine.FieldNo("Dimension Set ID"),
          DefaultVATAllocationLine.FieldNo("Shortcut Dimension 1 Code"), DefaultVATAllocationLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, TaxDiffJournalLine, TaxDiffJournalLine.FieldNo("Dimension Set ID"),
          TaxDiffJournalLine.FieldNo("Shortcut Dimension 1 Code"), TaxDiffJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, EmployeeJournalLine, EmployeeJournalLine.FieldNo("Dimension Set ID"),
          EmployeeJournalLine.FieldNo("Shortcut Dimension 1 Code"), EmployeeJournalLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, AbsenceHeader, AbsenceHeader.FieldNo("Dimension Set ID"),
          AbsenceHeader.FieldNo("Shortcut Dimension 1 Code"), AbsenceHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, AbsenceLine, AbsenceLine.FieldNo("Dimension Set ID"),
          AbsenceLine.FieldNo("Shortcut Dimension 1 Code"), AbsenceLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PayrollDocument, PayrollDocument.FieldNo("Dimension Set ID"),
          PayrollDocument.FieldNo("Shortcut Dimension 1 Code"), PayrollDocument.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PayrollDocumentLine, PayrollDocumentLine.FieldNo("Dimension Set ID"),
          PayrollDocumentLine.FieldNo("Shortcut Dimension 1 Code"), PayrollDocumentLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnGetTableNosWithGlobalDimensionCode', '', false, false)]
    local procedure AddingLocalTable(var TableBuffer: Record "Integer" temporary)
    begin
        AddTable(TableBuffer, DATABASE::"Vendor Agreement");
        AddTable(TableBuffer, DATABASE::"Customer Agreement");
        AddTable(TableBuffer, DATABASE::"FA Charge");
        AddTable(TableBuffer, DATABASE::"Payroll Element");
    end;

    local procedure AddTable(var TableBuffer: Record "Integer" temporary; TableID: Integer)
    begin
        if not TableBuffer.Get(TableID) then begin
            TableBuffer.Number := TableID;
            TableBuffer.Insert();
        end;
    end;
}

