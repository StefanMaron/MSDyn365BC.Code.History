#if not CLEAN20
interface "Electronic Signature Provider"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The interface will be removed. To get the signing key use the function GetCertPrivateKey from codeunit "Certificate Management".';
    ObsoleteTag = '20.0';

    [Obsolete('The function will be removed. To get the signing key use the function GetCertPrivateKey from codeunit "Certificate Management".', '19.1')]
    procedure GetSignature(DataInStream: InStream; var SignatureKey: Record "Signature Key"; SignatureOutStream: OutStream);
}

#endif