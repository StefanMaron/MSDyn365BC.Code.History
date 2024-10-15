interface "Electronic Signature Provider"
{
    procedure GetSignature(DataInStream: InStream; var SignatureKey: Record "Signature Key"; SignatureOutStream: OutStream);
}
