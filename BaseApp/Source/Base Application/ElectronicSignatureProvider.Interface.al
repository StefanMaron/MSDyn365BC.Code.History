interface "Electronic Signature Provider"
{
#if CLEAN19
    procedure GetSignature(DataInStream: InStream; XmlString: Text; SignatureOutStream: OutStream);
#else
    [Obsolete('Replaced by GetSignature function with XmlString parameter.', '19.1')]
    procedure GetSignature(DataInStream: InStream; var SignatureKey: Record "Signature Key"; SignatureOutStream: OutStream);
#endif
}
