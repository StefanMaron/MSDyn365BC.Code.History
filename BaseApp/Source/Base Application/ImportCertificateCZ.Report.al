report 31130 "Import Certificate CZ"
{
    Caption = 'Import Certificate';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(General)
                {
                    Caption = 'General';
                    field(CertificatePath; CertificatePath)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Certificate Path';
                        Editable = false;
                        ToolTip = 'Specifies the path or URL of the certificate file that will be imported.';

                        trigger OnAssistEdit()
                        var
                            FileManagement: Codeunit "File Management";
                        begin
                            CertificatePath := FileManagement.BLOBImport(CertificateTempBlob, '');
                        end;
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password of the private key of the certificate.';
                    }
                    field(WithoutPrivateKey; WithoutPrivateKey)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Import without private key';
                        ToolTip = 'Specifies whether the certificate will be imported with private key or without private key.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = ACTION::OK then
                Import;
        end;
    }

    labels
    {
    }

    var
        CertificateCZ: Record "Certificate CZ";
        CertificateTempBlob: Codeunit "Temp Blob";
        CertificatePath: Text;
        Password: Text;
        WithoutPrivateKey: Boolean;

    [Scope('OnPrem')]
    procedure SetCertificate(NewCertificateCZ: Record "Certificate CZ")
    begin
        CertificateCZ := NewCertificateCZ;
    end;

    local procedure Import()
    var
        TempCertificateCZ: Record "Certificate CZ" temporary;
        TempCertificateCZ2: Record "Certificate CZ" temporary;
        FileStream: InStream;
    begin
        if not CertificateTempBlob.HasValue then
            exit;

        CertificateTempBlob.CreateInStream(FileStream);

        TempCertificateCZ := CertificateCZ;
        if CertificateCZ.SaveCertificateFromStream(FileStream, Password, not WithoutPrivateKey) then begin
            CertificateCZ.UpdateCertificateInformation;
            CertificateCZ."User ID" := UserId;
            TempCertificateCZ2 := CertificateCZ;
            if not CertificateCZ.Modify(true) then begin
                CertificateCZ := TempCertificateCZ;
                CertificateCZ.Delete(false);
                CertificateCZ := TempCertificateCZ2;
                CertificateCZ.Insert(true);
            end;
        end;
    end;
}

