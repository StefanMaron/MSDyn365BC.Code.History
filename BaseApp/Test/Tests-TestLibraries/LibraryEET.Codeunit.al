#if not CLEAN18
codeunit 143011 "Library - EET"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateEETBusinessPremises(var EETBusinessPremises: Record "EET Business Premises"; Identification2: Code[6])
    begin
        with EETBusinessPremises do begin
            Init;
            Validate(Code, LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"EET Business Premises"));
            Insert(true);

            Description := Code;
            Identification := Identification2;
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateEETCashRegister(var EETCashRegister: Record "EET Cash Register"; BusinessPremisesCode: Code[10]; RegisterType: Option; RegisterNo: Code[20])
    var
        EETBusinessPremises: Record "EET Business Premises";
    begin
        if not EETBusinessPremises.Get(BusinessPremisesCode) then
            CreateEETBusinessPremises(EETBusinessPremises, GetDefaultBusinessPremisesIdentification);

        BusinessPremisesCode := EETBusinessPremises.Code;
        with EETCashRegister do begin
            Init;
            "Business Premises Code" := BusinessPremisesCode;
            Validate(Code, LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"EET Cash Register"));
            Insert(true);

            Validate("Register Type", RegisterType);
            Validate("Register No.", RegisterNo);
            Validate("Receipt Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode);
            Modify(true);
        end;
    end;

    local procedure CreateEETServiceSetup(var EETServiceSetup: Record "EET Service Setup")
    begin
        EETServiceSetup.Init();
        EETServiceSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetDefaultBusinessPremisesIdentification(): Code[6]
    begin
        exit('181');
    end;

    [Scope('OnPrem')]
    procedure SetEnabledEETService(Enabled: Boolean)
    var
        EETServiceSetup: Record "EET Service Setup";
    begin
        if not EETServiceSetup.Get then
            CreateEETServiceSetup(EETServiceSetup);

        EETServiceSetup.Enabled := Enabled;
        EETServiceSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetCertificateCode(CertificateCode: Code[10])
    var
        EETServiceSetup: Record "EET Service Setup";
    begin
        if not EETServiceSetup.Get then
            CreateEETServiceSetup(EETServiceSetup);

        EETServiceSetup.Validate("Certificate Code", CertificateCode);
        EETServiceSetup.Modify();
    end;
}

#endif