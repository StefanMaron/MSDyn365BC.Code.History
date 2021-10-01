codeunit 4112 "Image Helpers"
{

    trigger OnRun()
    begin
    end;

    var
        NoContentErr: Label 'The stream is empty.';
        UnknownImageTypeErr: Label 'Unknown image type.';

    procedure GetHTMLImgSrc(InStream: InStream): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        ImageFormatAsTxt: Text;
    begin
        if InStream.EOS then
            exit('');
        if not TryGetImageFormatAsTxt(InStream, ImageFormatAsTxt) then
            exit('');
        exit(StrSubstNo('data:image/%1;base64,%2', ImageFormatAsTxt, Base64Convert.ToBase64(InStream)));
    end;

    [TryFunction]
    local procedure TryGetImageFormatAsTxt(InStream: InStream; var ImageFormatAsTxt: Text)
    var
        Image: Codeunit Image;
    begin
        Image.FromStream(InStream);
        ImageFormatAsTxt := Image.GetFormatAsText();
    end;

    procedure GetImageType(InStream: InStream): Text
    var
        ImageFormatAsTxt: Text;
    begin
        if InStream.EOS then
            Error(NoContentErr);
        if not TryGetImageFormatAsTxt(InStream, ImageFormatAsTxt) then
            Error(UnknownImageTypeErr);
        exit(ImageFormatAsTxt);
    end;
}
