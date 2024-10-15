codeunit 143001 "ERM Dimension Subscriber - CZ"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryDim: Codeunit "Library - Dimension";

    [EventSubscriber(ObjectType::Codeunit, 131001, 'OnGetLocalTablesWithDimSetIDValidationIgnored', '', false, false)]
    [Scope('OnPrem')]
    procedure GetCountOfLocalTablesWithDimSetIDValidationIgnored(var CountOfTablesIgnored: Integer)
    begin
        // Specifies how many tables with "Dimension Set ID" field related to "Dimension Set Entry" table should not have OnValidate trigger which updates shortcut dimensions

        CountOfTablesIgnored += 4;
    end;

    [EventSubscriber(ObjectType::Codeunit, 131001, 'OnVerifyShorcutDimCodesUpdatedOnDimSetIDValidationLocal', '', false, false)]
    [Scope('OnPrem')]
    procedure VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(var TempAllObj: Record AllObj temporary; DimSetID: Integer; GlobalDim1ValueCode: Code[20]; GlobalDim2ValueCode: Code[20])
    var
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        CreditLine: Record "Credit Line";
    begin
        // Verifies local tables with "Dimension Set ID" field related to "Dimension Set Entry" and OnValidate trigger which updates shortcut dimensions

        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, CashDocumentHeader, CashDocumentHeader.FieldNo("Dimension Set ID"),
          CashDocumentHeader.FieldNo("Shortcut Dimension 1 Code"), CashDocumentHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, CashDocumentLine, CashDocumentLine.FieldNo("Dimension Set ID"),
          CashDocumentLine.FieldNo("Shortcut Dimension 1 Code"), CashDocumentLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, SalesAdvanceLetterHeader, SalesAdvanceLetterHeader.FieldNo("Dimension Set ID"),
          SalesAdvanceLetterHeader.FieldNo("Shortcut Dimension 1 Code"), SalesAdvanceLetterHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, SalesAdvanceLetterLine, SalesAdvanceLetterLine.FieldNo("Dimension Set ID"),
          SalesAdvanceLetterLine.FieldNo("Shortcut Dimension 1 Code"), SalesAdvanceLetterLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PurchAdvanceLetterHeader, PurchAdvanceLetterHeader.FieldNo("Dimension Set ID"),
          PurchAdvanceLetterHeader.FieldNo("Shortcut Dimension 1 Code"), PurchAdvanceLetterHeader.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, PurchAdvanceLetterLine, PurchAdvanceLetterLine.FieldNo("Dimension Set ID"),
          PurchAdvanceLetterLine.FieldNo("Shortcut Dimension 1 Code"), PurchAdvanceLetterLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, CreditLine, CreditLine.FieldNo("Dimension Set ID"),
          CreditLine.FieldNo("Global Dimension 1 Code"), CreditLine.FieldNo("Global Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
    end;
}

