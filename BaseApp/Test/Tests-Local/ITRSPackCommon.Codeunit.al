codeunit 148500 "IT RS Pack - Common"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Common]
    end;

    var
        FatturaPATxt: Label 'FATTURAPA', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAElectronicDocumentFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        UsageOption: Option;
    begin
        // [FEATURE] [FatturaPA] [Electronic Document]
        // [SCENARIO 259342] Electronic document format has FatturaPA setup for all Usage options
        with ElectronicDocumentFormat do
            for UsageOption := Usage::"Sales Invoice".AsInteger() to Usage::"Service Validation".AsInteger() do
                Get(FatturaPATxt, UsageOption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPASalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [FatturaPA] [Sales]
        // [SCENARIO 259342] Sales Setup has filled "Fattura PA Nos.", "Fattura PA Electronic Format" and "Validate Document On Posting" = FALSE
        with SalesReceivablesSetup do begin
            Get;
            TestField("Fattura PA Nos.");
            TestField("Fattura PA Electronic Format", FatturaPATxt);
            TestField("Validate Document On Posting", false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAServiceSetup()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [FatturaPA] [Service]
        // [SCENARIO 259342] Service Setup has "Validate Document On Posting" = FALSE
        with ServiceMgtSetup do begin
            Get;
            TestField("Validate Document On Posting", false);
        end;
    end;
}

