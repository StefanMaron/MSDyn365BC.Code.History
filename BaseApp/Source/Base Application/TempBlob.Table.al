table 99008535 TempBlob
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by BLOB Storage Module.';
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Blob; BLOB)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GlobalInStream: InStream;
        GlobalOutStream: OutStream;
        ReadLinesInitialized: Boolean;
        WriteLinesInitialized: Boolean;
        NoContentErr: Label 'The BLOB field is empty.';
        UnknownImageTypeErr: Label 'Unknown image type.';
        XmlCannotBeLoadedErr: Label 'The XML cannot be loaded.';

    procedure WriteAsText(Content: Text; Encoding: TextEncoding)
    var
        OutStr: OutStream;
    begin
        Clear(Blob);
        if Content = '' THEN
            exit;
        Blob.CREATEOUTSTREAM(OutStr, Encoding);
        OutStr.WRITETEXT(Content);
    end;

    procedure ReadAsText(LineSeparator: Text; Encoding: TextEncoding) Content: Text
    var
        InStream: InStream;
        ContentLine: Text;
    begin
        Blob.CREATEINSTREAM(InStream, Encoding);

        InStream.READTEXT(Content);
        WHILE not InStream.EOS DO BEGIN
            InStream.READTEXT(ContentLine);
            Content += LineSeparator + ContentLine;
        END;
    end;

    procedure ReadAsTextWithCRLFLineSeparator(): Text
    var
        CRLF: Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        exit(ReadAsText(CRLF, TEXTENCODING::UTF8));
    end;

    procedure StartReadingTextLines(Encoding: TextEncoding)
    begin
        Blob.CREATEINSTREAM(GlobalInStream, Encoding);
        ReadLinesInitialized := TRUE;
    end;

    procedure StartWritingTextLines(Encoding: TextEncoding)
    begin
        Clear(Blob);
        Blob.CREATEOUTSTREAM(GlobalOutStream, Encoding);
        WriteLinesInitialized := TRUE;
    end;

    procedure MoreTextLines(): Boolean
    begin
        if not ReadLinesInitialized THEN
            StartReadingTextLines(TEXTENCODING::Windows);
        exit(not GlobalInStream.EOS);
    end;

    procedure ReadTextLine(): Text
    var
        ContentLine: Text;
    begin
        if not MoreTextLines THEN
            exit('');
        GlobalInStream.READTEXT(ContentLine);
        exit(ContentLine);
    end;

    procedure WriteTextLine(Content: Text)
    begin
        if not WriteLinesInitialized THEN
            StartWritingTextLines(TEXTENCODING::Windows);
        GlobalOutStream.WRITETEXT(Content);
    end;

    procedure ToBase64String(): Text
    var
        IStream: InStream;
        Convert: DotNet Convert;
        MemoryStream: DotNet MemoryStream;
        Base64String: Text;
    begin
        if not Blob.HasValue THEN
            exit('');
        Blob.CREATEINSTREAM(IStream);
        MemoryStream := MemoryStream.MemoryStream;
        COPYSTREAM(MemoryStream, IStream);
        Base64String := Convert.ToBase64String(MemoryStream.ToArray);
        MemoryStream.Close;
        exit(Base64String);
    end;

    procedure FromBase64String(Base64String: Text)
    var
        OStream: OutStream;
        Convert: DotNet Convert;
        MemoryStream: DotNet MemoryStream;
    begin
        if Base64String = '' THEN
            exit;
        MemoryStream := MemoryStream.MemoryStream(Convert.FromBase64String(Base64String));
        Blob.CREATEOUTSTREAM(OStream);
        MemoryStream.WriteTo(OStream);
        MemoryStream.Close;
    end;

    procedure GetHTMLImgSrc(): Text
    var
        ImageFormatAsTxt: Text;
    begin
        if not Blob.HasValue THEN
            exit('');
        if not TryGetImageFormatAsTxt(ImageFormatAsTxt) THEN
            exit('');
        exit(STRSUBSTNO('data:image/%1;base64,%2', ImageFormatAsTxt, ToBase64String));
    end;

    [TryFunction]
    local procedure TryGetImageFormatAsTxt(var ImageFormatAsTxt: Text)
    var
        Image: DotNet Image;
        ImageFormatConverter: DotNet ImageFormatConverter;
        InStream: InStream;
    begin
        Blob.CREATEINSTREAM(InStream);
        Image := Image.FromStream(InStream);
        ImageFormatConverter := ImageFormatConverter.ImageFormatConverter;
        ImageFormatAsTxt := ImageFormatConverter.ConvertToString(Image.RawFormat);
    end;

    procedure GetImageType(): Text
    var
        ImageFormatAsTxt: Text;
    begin
        if not Blob.HasValue THEN
            Error(NoContentErr);
        if not TryGetImageFormatAsTxt(ImageFormatAsTxt) THEN
            Error(UnknownImageTypeErr);
        exit(ImageFormatAsTxt);
    end;

    [TryFunction]
    procedure TryDownloadFromUrl(Url: Text)
    var
        FileManagement: Codeunit "File Management";
        WebClient: DotNet WebClient;
        MemoryStream: DotNet MemoryStream;
        OutStr: OutStream;
    begin
        FileManagement.IsAllowedPath(Url, FALSE);
        WebClient := WebClient.WebClient;
        MemoryStream := MemoryStream.MemoryStream(WebClient.DownloadData(Url));
        Blob.CREATEOUTSTREAM(OutStr);
        COPYSTREAM(OutStr, MemoryStream);
    end;

    [TryFunction]
    local procedure TryGetXMLAsText(var Xml: Text)
    var
        XmlDoc: DotNet XmlDocument;
        InStr: InStream;
    begin
        Blob.CREATEINSTREAM(InStr);
        XmlDoc := XmlDoc.XmlDocument;
        XmlDoc.PreserveWhitespace := FALSE;
        XmlDoc.Load(InStr);
        Xml := XmlDoc.OuterXml;
    end;

    procedure GetXMLAsText(): Text
    var
        Xml: Text;
    begin
        if not Blob.HasValue THEN
            Error(NoContentErr);
        if not TryGetXMLAsText(Xml) THEN
            Error(XmlCannotBeLoadedErr);
        exit(Xml);
    end;
}

