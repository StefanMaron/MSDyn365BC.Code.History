codeunit 4900 "SMTP Mail Internals"
{
    Access = Internal;

    [InternalEvent(false)]
    procedure OnAfterCreateMessage(Email: DotNet MimeMessage; BodyBuilder: DotNet MimeBodyBuilder)
    begin
    end;
}