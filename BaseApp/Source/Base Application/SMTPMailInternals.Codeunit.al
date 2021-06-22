codeunit 4900 "SMTP Mail Internals"
{
    Access = Internal;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateMessage(Email: DotNet MimeMessage; BodyBuilder: DotNet MimeBodyBuilder)
    begin
    end;
}