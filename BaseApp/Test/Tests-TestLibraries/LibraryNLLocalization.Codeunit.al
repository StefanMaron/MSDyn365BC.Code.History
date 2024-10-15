codeunit 143000 "Library - NL Localization"
{
    // Library containing functions specific to NL Localization objects, hence meant to be kept at NL Branch Only.


    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateCBGStatement(var CBGStatement: Record "CBG Statement"; JournalTemplateName: Code[10])
    begin
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", JournalTemplateName);
        CBGStatement.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; JournalTemplateName: Code[10]; No: Integer; StatementType: Option; StatementNo: Code[20]; AccountType: Option; AccountNo: Code[20]; Debit: Decimal; Credit: Decimal)
    var
        RecRef: RecordRef;
    begin
        CBGStatementLine.Init();
        CBGStatementLine.Validate("Journal Template Name", JournalTemplateName);
        CBGStatementLine.Validate("No.", No);
        RecRef.GetTable(CBGStatementLine);
        CBGStatementLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, CBGStatementLine.FieldNo("Line No.")));
        CBGStatementLine.Insert(true);
        CBGStatementLine.Validate("Statement Type", StatementType);
        CBGStatementLine.Validate("Statement No.", StatementNo);
        CBGStatementLine.Validate(Date, WorkDate);
        CBGStatementLine.Validate("Account Type", AccountType);
        CBGStatementLine.Validate("Account No.", AccountNo);
        CBGStatementLine.Validate(Debit, Debit);
        CBGStatementLine.Validate(Credit, Credit);
        CBGStatementLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateElecTaxDeclarationHeader(var ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header"; DeclarationType: Option)
    begin
        ElecTaxDeclarationHeader.Init();
        ElecTaxDeclarationHeader.Validate("Declaration Type", DeclarationType);
        ElecTaxDeclarationHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateExportProtocol(var ExportProtocol: Record "Export Protocol")
    begin
        ExportProtocol.Init();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateGUID);
        ExportProtocol.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFreelyTransferableMaximum(CountryRegionCode: Code[10]; CurrencyCode: Code[10])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        FreelyTransferableMaximum.Init();
        FreelyTransferableMaximum.Validate("Country/Region Code", CountryRegionCode);
        FreelyTransferableMaximum.Validate("Currency Code", CurrencyCode);
        FreelyTransferableMaximum.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CheckAndCreateFreelyTransferableMaximum(CountryRegionCode: Code[10]; CurrencyCode: Code[10])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        if not FreelyTransferableMaximum.Get(CountryRegionCode, CurrencyCode) then
            CreateFreelyTransferableMaximum(CountryRegionCode, CurrencyCode);
    end;

    [Scope('OnPrem')]
    procedure CreateTransactionMode(var TransactionMode: Record "Transaction Mode"; AccountType: Option)
    begin
        TransactionMode.Init();
        TransactionMode.Validate("Account Type", AccountType);
        TransactionMode.Validate(Code, LibraryUtility.GenerateRandomCode(TransactionMode.FieldNo(Code), DATABASE::"Transaction Mode"));
        TransactionMode.Insert(true);
    end;
}

