codeunit 131009 "Library - Setup Storage"
{
    Permissions = TableData "General Ledger Setup" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TempIntegerStoredTables: Record "Integer" temporary;
        Assert: Codeunit Assert;
        TableBackupErr: Label 'Table %1 already added to backup', Comment = '%1 = Table Caption';
        OnlyOneEntryAllowedErr: Label 'Setup table with only one entry is allowed';
        CompositePrimaryKeyErr: Label 'Composite primary key is not allowed';
        RecordRefStorage: array[100] of RecordRef;

    procedure Save(TableId: Integer)
    var
        RecRef: RecordRef;
    begin
        if TempIntegerStoredTables.Get(TableId) then
            Error(TableBackupErr, TableId);

        RecRef.Open(TableId);
        Assert.AreEqual(1, RecRef.Count, OnlyOneEntryAllowedErr);
        RecRef.Find();
        ValidatePrimaryKey(RecRef);

        TempIntegerStoredTables.Number := TableId;
        TempIntegerStoredTables.Insert(true);
        RecordRefStorage[TempIntegerStoredTables.Count] := RecRef;
    end;

    [Scope('OnPrem')]
    procedure SaveSalesSetup()
    begin
        Save(DATABASE::"Sales & Receivables Setup");
    end;

    [Scope('OnPrem')]
    procedure SavePurchasesSetup()
    begin
        Save(DATABASE::"Purchases & Payables Setup");
    end;

    [Scope('OnPrem')]
    procedure SaveGeneralLedgerSetup()
    begin
        Save(DATABASE::"General Ledger Setup");
    end;

    [Scope('OnPrem')]
    procedure SaveCompanyInformation()
    begin
        Save(DATABASE::"Company Information");
    end;

    [Scope('OnPrem')]
    procedure SaveManufacturingSetup()
    begin
        Save(DATABASE::"Manufacturing Setup");
    end;

    procedure Restore()
    var
        RecordRefSource: RecordRef;
        RecordRefDestination: RecordRef;
        Index: Integer;
    begin
        Index := TempIntegerStoredTables.Count();
        while Index > 0 do begin
            RecordRefSource := RecordRefStorage[Index];
            RecordRefDestination.Open(RecordRefSource.Number);
            CopyFields(RecordRefSource, RecordRefDestination);
            RecordRefDestination.Modify();
            RecordRefDestination.Close();
            Index -= 1;
        end;
    end;

    local procedure ValidatePrimaryKey(var RecRef: RecordRef)
    var
        KeyRef: KeyRef;
    begin
        KeyRef := RecRef.KeyIndex(1);
        Assert.AreEqual(1, KeyRef.FieldCount, CompositePrimaryKeyErr);
    end;

    local procedure CopyFields(RecordRefSource: RecordRef; var RecordRefDestination: RecordRef)
    var
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecordRefSource.FieldCount do begin
            SourceFieldRef := RecordRefSource.FieldIndex(i);
            if SourceFieldRef.Class = FieldClass::Normal then begin
                DestinationFieldRef := RecordRefDestination.Field(SourceFieldRef.Number);
                DestinationFieldRef.Value(SourceFieldRef.Value)
            end;
        end
    end;
}

