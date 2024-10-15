codeunit 11409 "Elec. Tax Declaration Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        SchemaVersionTxt: Label '2019v13.0', Locked = true;
        BDDataEndpointTxt: Label 'http://www.nltaxonomie.nl/nt13/bd/20181212/dictionary/bd-data', Locked = true;
        BDTuplesEndpointTxt: Label 'http://www.nltaxonomie.nl/nt13/bd/20181212/dictionary/bd-tuples', Locked = true;
        VATDeclarationSchemaEndpointTxt: Label 'http://www.nltaxonomie.nl/nt13/bd/20181212/entrypoints/bd-rpt-ob-aangifte-2019.xsd', Locked = true;
        ICPDeclarationSchemaEndpointTxt: Label 'http://www.nltaxonomie.nl/nt13/bd/20181212/entrypoints/bd-rpt-icp-opgaaf-2019.xsd', Locked = true;

    procedure GetSchemaVersion() SchemaVersion: Text[10]
    var
        Handled: Boolean;
    begin
        OnBeforeGetSchemaVersion(Handled, SchemaVersion);
        if Handled then
            exit(SchemaVersion);
        exit(SchemaVersionTxt);
    end;

    procedure GetBDDataEndpoint() BDDataEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetBDDataEndpoint(Handled, BDDataEndpoint);
        if Handled then
            exit(BDDataEndpoint);
        exit(BDDataEndpointTxt);
    end;

    procedure GetBDTuplesEndpoint() BDTuplesEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetBDTuplesEndpoint(Handled, BDTuplesEndpoint);
        if Handled then
            exit(BDTuplesEndpoint);
        exit(BDTuplesEndpointTxt);
    end;

    procedure GetVATDeclarationSchemaEndpoint() VATDeclarationSchemaEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetVATDeclarationSchemaEndpoint(Handled, VATDeclarationSchemaEndpoint);
        if Handled then
            exit(VATDeclarationSchemaEndpoint);
        exit(VATDeclarationSchemaEndpointTxt);
    end;

    procedure GetICPDeclarationSchemaEndpoint() ICPDeclarationSchemaEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetICPDeclarationSchemaEndpoint(Handled, ICPDeclarationSchemaEndpoint);
        if Handled then
            exit(ICPDeclarationSchemaEndpoint);
        exit(ICPDeclarationSchemaEndpointTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSchemaVersion(var Handled: Boolean; var SchemaVersion: Text[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBDDataEndpoint(var Handled: Boolean; var BDDataEndpoint: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBDTuplesEndpoint(var Handled: Boolean; var BDTuplesEndpoint: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVATDeclarationSchemaEndpoint(var Handled: Boolean; var VATDeclarationSchemaEndpoint: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetICPDeclarationSchemaEndpoint(var Handled: Boolean; var ICPDeclarationSchemaEndpoint: Text[250])
    begin
    end;
}

