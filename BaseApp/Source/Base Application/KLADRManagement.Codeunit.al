codeunit 14950 "KLADR Management"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure LookupAddress(var AltAddr: Record "Alternative Address"; Level: Integer)
    var
        KLADRAddr: Record "KLADR Address";
        KLADRForm: Page "KLADR Addresses";
        ParentCode: Text[23];
        CurrCode: Text[23];
    begin
        if (AltAddr."KLADR Code" = '') and (Level <> 1) then
            exit;

        ParentCode := KLADRAddr.GetParentCode(AltAddr."KLADR Code", Level);

        KLADRAddr.Reset();
        KLADRAddr.SetCurrentKey(Level, Parent, Name);
        KLADRAddr.SetRange(Level, Level);
        if Level > 1 then
            KLADRAddr.SetRange(Parent, ParentCode);
        CurrCode := KLADRAddr.GetParentCode(AltAddr."KLADR Code", Level + 1);
        if not KLADRAddr.IsEmpty() then begin
            if KLADRAddr.Get(CurrCode) then;
            KLADRForm.SetTableView(KLADRAddr);
            KLADRForm.SetRecord(KLADRAddr);
            KLADRForm.LookupMode(true);
            if KLADRForm.RunModal = ACTION::LookupOK then begin
                KLADRForm.GetRecord(KLADRAddr);
                if CurrCode <> KLADRAddr.Code then begin
                    AltAddr."KLADR Code" := KLADRAddr.Code;
                    AltAddr.SetValues(Level, KLADRAddr.Name, KLADRAddr."Category Code");
                    if KLADRAddr.Index <> '' then
                        AltAddr."Post Code" := KLADRAddr.Index;
                    if KLADRAddr.GNINMB <> '' then
                        AltAddr."Tax Inspection Code" := KLADRAddr.GNINMB;
                end;
            end;
        end;
    end;
}

