codeunit 143002 "ERM Dimension Subscriber - FI"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryDim: Codeunit "Library - Dimension";
#if not CLEAN22
    [Obsolete('Moved to Automatic Account Codes app.', '22.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnVerifyShorcutDimCodesUpdatedOnDimSetIDValidationLocal', '', false, false)]
    local procedure VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(var TempAllObj: Record AllObj temporary; DimSetID: Integer; GlobalDim1ValueCode: Code[20]; GlobalDim2ValueCode: Code[20])
    var
        AutomaticAccLine: Record "Automatic Acc. Line";
    begin
        // Verifies local tables with "Dimension Set ID" field related to "Dimension Set Entry" and OnValidate trigger which updates shortcut dimensions

        LibraryDim.VerifyShorcutDimCodesUpdatedOnDimSetIDValidation(
          TempAllObj, AutomaticAccLine, AutomaticAccLine.FieldNo("Dimension Set ID"),
          AutomaticAccLine.FieldNo("Shortcut Dimension 1 Code"), AutomaticAccLine.FieldNo("Shortcut Dimension 2 Code"),
          DimSetID, GlobalDim1ValueCode, GlobalDim2ValueCode);
    end;
#endif
}

