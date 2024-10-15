codeunit 144061 "UT TAB INTRSTAT"
{
    // Test for feature - INTRASTAT.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TariffNoFieldLength()
    var
        IntraFormBuffer: Record "Intra - form Buffer";
        TariffNumber: Record "Tariff Number";
    begin
        // Purpose of the test is to validate table 'Intra - form Buffer' can handle Tariff No.
        // field of maximum length defined by Tariff Number "No."
        TariffNumber.Init();
        TariffNumber."No." := PadStr(TariffNumber."No.", MaxStrLen(TariffNumber."No."), '9');
        TariffNumber.Insert();

        IntraFormBuffer."Tariff No." := TariffNumber."No.";
        IntraFormBuffer.TestField("Tariff No.", TariffNumber."No.");
    end;
}

