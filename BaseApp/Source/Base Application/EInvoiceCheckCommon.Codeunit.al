codeunit 10629 "E-Invoice Check Common"
{

    trigger OnRun()
    begin
    end;

    var
        InvalidCurrencyExchangeRateErr: Label 'The %1 field on the %2 page has an invalid value of %3. %5 is unable to calculate the exchange rate. The electronic invoice document cannot be created for document number %4.', Comment = '%5 - product name';

    [Scope('OnPrem')]
    procedure CheckCurrencyCode(CurrencyCode: Code[10]; DocumentNumber: Code[20]; PostingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // CurrencyCode is empty - ok (we'll use LCY later in the exported E-Invoice)
        if CurrencyCode = '' then
            exit;

        // CurrencyCode is equal to LCY - ok
        GeneralLedgerSetup.Get();
        if CurrencyCode = GeneralLedgerSetup."LCY Code" then
            exit;

        // CurrencyCode <> LCY - found in Currencies - the ExchangeRate function below will ensure we do have an exchange rate
        // for this currency
        if CurrencyExchangeRate.ExchangeRate(PostingDate, CurrencyCode) = 0 then
            Error(InvalidCurrencyExchangeRateErr, Currency.FieldCaption("Currency Factor"),
              Currency.TableCaption, Currency."Currency Factor", DocumentNumber, PRODUCTNAME.Full);
    end;
}

