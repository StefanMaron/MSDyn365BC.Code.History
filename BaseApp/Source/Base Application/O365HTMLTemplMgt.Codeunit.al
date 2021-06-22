codeunit 2114 "O365 HTML Templ. Mgt."
{
    Permissions = TableData "Payment Reporting Argument" = rimd;

    trigger OnRun()
    begin
    end;

    var
        InvoiceNoTxt: Label 'Invoice No.';
        EstimateNoTxt: Label 'Estimate No.';
        ValidUntilTxt: Label 'Valid until';
        TotalTxt: Label 'Total %1', Comment = '%1 = Currency Code';
        YourInvoiceTxt: Label 'Your Invoice';
        YourEstimateTxt: Label 'Your Estimate';
        WantToPayOnlineQst: Label 'Want to pay online?';
        PaymentInvitationTxt: Label 'You can pay this invoice online. It''s quick and easy.';
        CompanyInformation: Record "Company Information";
        CompanyInfoRead: Boolean;
        EmailSentToTxt: Label 'This email was sent to';
        FollowOnSocialTxt: Label 'Follow %1 on Social', Comment = '%1 - company name';
        ThankYouForYourBusinessTxt: Label 'Thank you for your business.';
        InvoiceFromTitleTxt: Label 'Invoice from %1', Comment = 'This is a mail title. %1 - company name';
        EstimateFromTitleTxt: Label 'Estimate from %1', Comment = 'This is a mail title. %1 - company name';

    procedure CreateEmailBodyFromReportSelections(ReportSelections: Record "Report Selections"; RecordVariant: Variant; MailTo: Text; MailText: Text) OutputFileName: Text[250]
    var
        FileMgt: Codeunit "File Management";
        HTMLText: Text;
    begin
        OutputFileName := CopyStr(FileMgt.ServerTempFileName('html'), 1, 250);

        HTMLText := CreateHTMLTextFromReportSelections(ReportSelections, RecordVariant, MailTo, MailText);

        SaveHTML(OutputFileName, HTMLText);
    end;

    local procedure CreateHTMLTextFromReportSelections(ReportSelections: Record "Report Selections"; RecordVariant: Variant; MailTo: Text; MailText: Text) HTMLText: Text
    begin
        with ReportSelections do begin
            HTMLText := GetTemplateContent("Email Body Layout Code");

            case Usage of
                Usage::"S.Invoice":
                    FillSalesInvoiceHTML(RecordVariant, HTMLText, MailTo, MailText);
                Usage::"S.Invoice Draft":
                    FillSalesDraftInvoiceHTML(RecordVariant, HTMLText, MailTo, MailText);
                Usage::"S.Quote":
                    FillSalesEstimateHTML(RecordVariant, HTMLText, MailTo, MailText);
            end;
        end;
    end;

    local procedure FillSalesDraftInvoiceHTML(SalesHeader: Record "Sales Header"; var HTMLText: Text; MailTo: Text; MailText: Text)
    var
        PaymentServicesSectionHTMLText: Text;
        PaymentServiceRowHTMLText: Text;
        SocialNetworksSectionHTMLText: Text;
        SocialNetworkRowSectionHTMLText: Text;
    begin
        SliceSalesCoverLetterTemplate(HTMLText, PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText,
          SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText);

        FillCommonParameters(HTMLText, SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText, MailTo, MailText);
        FillParameterValueEncoded(HTMLText, 'MailTitle', StrSubstNo(InvoiceFromTitleTxt, CompanyInformation.Name));
        FillParameterValueEncoded(HTMLText, 'YourDocument', YourInvoiceTxt);

        FillParameterValueEncoded(HTMLText, 'DocumentNoLbl', InvoiceNoTxt);
        FillParameterValueEncoded(HTMLText, 'DocumentNo', SalesHeader."No.");
        FillParameterValueEncoded(HTMLText, 'DateLbl', SalesHeader.FieldCaption("Due Date"));
        FillParameterValueEncoded(HTMLText, 'Date', Format(SalesHeader."Due Date"));
        FillParameterValueEncoded(HTMLText, 'TotalAmountLbl', StrSubstNo(TotalTxt, SalesHeader.GetCurrencySymbol));
        SalesHeader.CalcFields("Amount Including VAT");
        FillParameterValueEncoded(HTMLText, 'TotalAmount', Format(SalesHeader."Amount Including VAT"));

        FillSalesDraftInvoicePaymentServices(HTMLText, PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText, SalesHeader);
    end;

    local procedure FillSalesInvoiceHTML(SalesInvoiceHeader: Record "Sales Invoice Header"; var HTMLText: Text; MailTo: Text; MailText: Text)
    var
        PaymentServicesSectionHTMLText: Text;
        PaymentServiceRowHTMLText: Text;
        SocialNetworksSectionHTMLText: Text;
        SocialNetworkRowSectionHTMLText: Text;
    begin
        SliceSalesCoverLetterTemplate(HTMLText, PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText,
          SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText);

        FillCommonParameters(HTMLText, SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText, MailTo, MailText);
        FillParameterValueEncoded(HTMLText, 'MailTitle', StrSubstNo(InvoiceFromTitleTxt, CompanyInformation.Name));
        FillParameterValueEncoded(HTMLText, 'YourDocument', YourInvoiceTxt);
        FillParameterValueEncoded(HTMLText, 'DocumentNoLbl', InvoiceNoTxt);
        FillParameterValueEncoded(HTMLText, 'DocumentNo', SalesInvoiceHeader."No.");
        FillParameterValueEncoded(HTMLText, 'DateLbl', SalesInvoiceHeader.FieldCaption("Due Date"));
        FillParameterValueEncoded(HTMLText, 'Date', Format(SalesInvoiceHeader."Due Date"));
        FillParameterValueEncoded(HTMLText, 'TotalAmountLbl', StrSubstNo(TotalTxt, SalesInvoiceHeader.GetCurrencySymbol));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        FillParameterValueEncoded(HTMLText, 'TotalAmount', Format(SalesInvoiceHeader."Amount Including VAT"));

        SalesInvoiceHeader.CalcFields(Cancelled);
        if not SalesInvoiceHeader.Cancelled then
            FillSalesInvoicePaymentServices(HTMLText, PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText, SalesInvoiceHeader);
    end;

    local procedure FillSalesEstimateHTML(SalesHeader: Record "Sales Header"; var HTMLText: Text; MailTo: Text; MailText: Text)
    var
        PaymentServicesSectionHTMLText: Text;
        PaymentServiceRowHTMLText: Text;
        SocialNetworksSectionHTMLText: Text;
        SocialNetworkRowSectionHTMLText: Text;
    begin
        SliceSalesCoverLetterTemplate(HTMLText, PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText,
          SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText);

        FillCommonParameters(HTMLText, SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText, MailTo, MailText);
        FillParameterValueEncoded(HTMLText, 'MailTitle', StrSubstNo(EstimateFromTitleTxt, CompanyInformation.Name));
        FillParameterValueEncoded(HTMLText, 'YourDocument', YourEstimateTxt);

        FillParameterValueEncoded(HTMLText, 'DocumentNoLbl', EstimateNoTxt);
        FillParameterValueEncoded(HTMLText, 'DocumentNo', SalesHeader."No.");
        FillParameterValueEncoded(HTMLText, 'DateLbl', ValidUntilTxt);
        FillParameterValueEncoded(HTMLText, 'Date', Format(SalesHeader."Quote Valid Until Date"));
        FillParameterValueEncoded(HTMLText, 'TotalAmountLbl', StrSubstNo(TotalTxt, SalesHeader.GetCurrencySymbol));
        SalesHeader.CalcFields("Amount Including VAT");
        FillParameterValueEncoded(HTMLText, 'TotalAmount', Format(SalesHeader."Amount Including VAT"));
    end;

    local procedure GetCompanyInfo()
    begin
        if CompanyInfoRead then
            exit;

        CompanyInformation.Get();
        CompanyInfoRead := true;
    end;

    local procedure GetCompanyLogoScaledDimensions(var TempBlob: Codeunit "Temp Blob"; var ScaledWidth: Integer; var ScaledHeight: Integer; ScaleToWidth: Integer; ScaleToHeight: Integer)
    var
        Image: DotNet Image;
        InStream: InStream;
        HorizontalFactor: Decimal;
        VerticalFactor: Decimal;
    begin
        if not TempBlob.HasValue then
            exit;
        TempBlob.CreateInStream(InStream);
        Image := Image.FromStream(InStream);

        if Image.Height <> 0 then
            HorizontalFactor := ScaleToHeight / Image.Height;
        if Image.Width <> 0 then
            VerticalFactor := ScaleToWidth / Image.Width;

        if HorizontalFactor < VerticalFactor then
            VerticalFactor := HorizontalFactor
        else
            HorizontalFactor := VerticalFactor;

        ScaledHeight := Round(Image.Height * HorizontalFactor, 1);
        ScaledWidth := Round(Image.Width * VerticalFactor, 1);
    end;

    procedure GetTemplateContent(TemplateCode: Code[20]) TemplateContent: Text
    var
        O365HTMLTemplate: Record "O365 HTML Template";
        MediaResources: Record "Media Resources";
        InStream: InStream;
        Buffer: Text;
    begin
        O365HTMLTemplate.Get(TemplateCode);
        O365HTMLTemplate.TestField("Media Resources Ref");
        MediaResources.Get(O365HTMLTemplate."Media Resources Ref");
        MediaResources.CalcFields(Blob);
        MediaResources.Blob.CreateInStream(InStream, TEXTENCODING::UTF8);
        while not InStream.EOS do begin
            InStream.Read(Buffer);
            TemplateContent += Buffer;
        end;
    end;

    local procedure GetPaymentServiceLogoAsText(PaymentReportingArgument: Record "Payment Reporting Argument"): Text
    var
        O365PaymentServiceLogo: Record "O365 Payment Service Logo";
        MediaResources: Record "Media Resources";
        ImageHelpers: Codeunit "Image Helpers";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        if O365PaymentServiceLogo.FindO365Logo(PaymentReportingArgument) then begin
            MediaResources.Get(O365PaymentServiceLogo."Media Resources Ref");
            TempBlob.FromRecord(MediaResources, MediaResources.FieldNo(Blob));
        end else
            TempBlob.FromRecord(PaymentReportingArgument, PaymentReportingArgument.FieldNo(Logo));

        ResizePaymentServiceLogoIfNeeded(TempBlob);

        TempBlob.CreateInStream(InStream);
        exit(ImageHelpers.GetHTMLImgSrc(InStream));
    end;

    local procedure GetPrimaryColorValue(): Code[10]
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        GetCompanyInfo;

        if CompanyInformation."Brand Color Value" = '' then
            if O365BrandColor.FindFirst then
                exit(O365BrandColor."Color Value");

        exit(CompanyInformation."Brand Color Value");
    end;

    local procedure GetSocialNetworksHTMLPart(SocialNetworksSectionHTMLText: Text; SocialNetworkRowSectionHTMLText: Text) SocialNetworksHTMLPart: Text
    var
        O365SocialNetwork: Record "O365 Social Network";
    begin
        O365SocialNetwork.SetFilter(URL, '<>%1', '');
        O365SocialNetwork.SetFilter("Media Resources Ref", '<>%1', '');
        if O365SocialNetwork.FindFirst then begin
            SocialNetworksHTMLPart := SocialNetworksSectionHTMLText;
            GetCompanyInfo;
            FillParameterValueEncoded(
              SocialNetworksHTMLPart,
              'FollowOnSocial',
              StrSubstNo(FollowOnSocialTxt, CompanyInformation.Name));
            FillParameterValue(
              SocialNetworksHTMLPart,
              'CoverLetterSocialRow',
              GetSocialsRowsHTMLPart(O365SocialNetwork, SocialNetworkRowSectionHTMLText));
        end;
    end;

    local procedure GetSocialsRowsHTMLPart(var O365SocialNetwork: Record "O365 Social Network"; SocialNetworkRowSectionHTMLText: Text) HTMLText: Text
    var
        MediaResources: Record "Media Resources";
    begin
        repeat
            if MediaResources.Get(O365SocialNetwork."Media Resources Ref") then
                HTMLText += GetSocialsRowHTMLPart(O365SocialNetwork, SocialNetworkRowSectionHTMLText);
        until O365SocialNetwork.Next = 0;
    end;

    local procedure GetSocialsRowHTMLPart(O365SocialNetwork: Record "O365 Social Network"; SocialNetworkRowSectionHTMLText: Text) RowHTMLText: Text
    begin
        RowHTMLText := SocialNetworkRowSectionHTMLText;
        FillParameterValueEncoded(RowHTMLText, 'SocialURL', O365SocialNetwork.URL);
        FillParameterValueEncoded(RowHTMLText, 'SocialAlt', O365SocialNetwork.Name);
        FillParameterValue(RowHTMLText, 'SocialLogo', GetSocialNetworkLogoAsTxt(O365SocialNetwork));
    end;

    local procedure GetSocialNetworkLogoAsTxt(O365SocialNetwork: Record "O365 Social Network"): Text
    var
        MediaResources: Record "Media Resources";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
    begin
        if not MediaResources.Get(O365SocialNetwork."Media Resources Ref") then
            exit('');

        MediaResources.Blob.CreateInStream(InStream);
        exit(ImageHelpers.GetHTMLImgSrc(InStream));
    end;

    local procedure FillCompanyInfoSection(var HTMLText: Text)
    var
        FormatAddr: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
    begin
        GetCompanyInfo;
        FormatAddr.Company(CompanyAddr, CompanyInformation);
        FillParameterValueEncoded(HTMLText, 'CompanyName', CompanyInformation.Name);
        FillParameterValueEncoded(HTMLText, 'CompanyAddress', MakeFullCompanyAddress(CompanyAddr));
        FillParameterValueEncoded(HTMLText, 'CompanyPhoneNo', CompanyInformation."Phone No.");
    end;

    local procedure FillCompanyLogo(var HTMLText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        ImageHandlerManagement: Codeunit "Image Handler Management";
        InStream: InStream;
        Width: Integer;
        Height: Integer;
        MaxWidth: Integer;
        MaxHeight: Integer;
    begin
        MaxWidth := 246;
        MaxHeight := 80;

        GetCompanyInfo;
        TempBlob.FromRecord(CompanyInformation, CompanyInformation.FieldNo(Picture));
        if ImageHandlerManagement.ScaleDownFromBlob(TempBlob, MaxWidth, MaxHeight) then;

        OnResizeCompanyLogo(TempBlob);

        GetCompanyLogoScaledDimensions(TempBlob, Width, Height, MaxWidth, MaxHeight);
        TempBlob.CreateInStream(InStream);
        FillParameterValue(HTMLText, 'CompanyLogo', ImageHelpers.GetHTMLImgSrc(InStream));
        FillParameterValueEncoded(HTMLText, 'CompanyLogoWidth', Format(Width, 0, 9));
        FillParameterValueEncoded(HTMLText, 'CompanyLogoHeight', Format(Height, 0, 9));
    end;

    procedure FillCommonParameters(var HTMLText: Text; SocialNetworksSectionHTMLText: Text; SocialNetworkRowSectionHTMLText: Text; MailTo: Text; MailText: Text)
    begin
        FillCompanyLogo(HTMLText);

        FillParameterValueEncoded(HTMLText, 'ThankYouForYourBusiness', ThankYouForYourBusinessTxt);
        FillParameterValue(HTMLText, 'SocialNetworks',
          GetSocialNetworksHTMLPart(SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText));

        FillCompanyInfoSection(HTMLText);

        FillParameterValueEncoded(HTMLText, 'EmailSentToLbl', EmailSentToTxt);
        FillParameterValueEncoded(HTMLText, 'MailTo', MailTo);
        FillParameterValueEncoded(HTMLText, 'PrimaryColor', GetPrimaryColorValue);

        FillParameterValue(HTMLText, 'MailText', EncodeMessage(MailText, false));
    end;

    procedure FillParameterValueEncoded(var HTMLText: Text; ParamenterName: Text; ParameterValue: Text)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        FillParameterValue(HTMLText, ParamenterName, TypeHelper.HtmlEncode(ParameterValue));
    end;

    procedure FillParameterValue(var HTMLText: Text; ParamenterName: Text; ParameterValue: Text)
    begin
        ReplaceHTMLText(HTMLText, MakeParameterNameString(ParamenterName), ParameterValue);
    end;

    local procedure FillSalesDraftInvoicePaymentServices(var HTMLText: Text; PaymentServicesSectionHTMLText: Text; PaymentServiceRowHTMLText: Text; SalesHeader: Record "Sales Header")
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        TempPaymentReportingArgument: Record "Payment Reporting Argument" temporary;
    begin
        PaymentServiceSetup.CreateReportingArgs(TempPaymentReportingArgument, SalesHeader);
        FillPaymentServicesPart(HTMLText, TempPaymentReportingArgument, PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText);
    end;

    local procedure FillSalesInvoicePaymentServices(var HTMLText: Text; PaymentServicesSectionHTMLText: Text; PaymentServiceRowHTMLText: Text; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        TempPaymentReportingArgument: Record "Payment Reporting Argument" temporary;
    begin
        PaymentServiceSetup.CreateReportingArgs(TempPaymentReportingArgument, SalesInvoiceHeader);
        FillPaymentServicesPart(HTMLText, TempPaymentReportingArgument, PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText);
    end;

    local procedure FillPaymentServicesPart(var HTMLText: Text; var TempPaymentReportingArgument: Record "Payment Reporting Argument" temporary; PaymentServicesSectionHTMLText: Text; PaymentServiceRowHTMLText: Text)
    var
        PaymentServicesHTMLText: Text;
        PaymentServicesRowsHTMLText: Text;
    begin
        if TempPaymentReportingArgument.FindSet then begin
            PaymentServicesHTMLText := PaymentServicesSectionHTMLText;

            FillParameterValueEncoded(PaymentServicesHTMLText, 'WantToPayOnline', WantToPayOnlineQst);
            FillParameterValueEncoded(PaymentServicesHTMLText, 'PaymentInvitation', PaymentInvitationTxt);

            repeat
                PaymentServicesRowsHTMLText += FillPaymentServiceRowPart(TempPaymentReportingArgument, PaymentServiceRowHTMLText);
            until TempPaymentReportingArgument.Next = 0;

            FillParameterValue(PaymentServicesHTMLText, 'PaymentServicesRows', PaymentServicesRowsHTMLText);
            FillParameterValue(HTMLText, 'PaymentSevices', PaymentServicesHTMLText);
        end;
    end;

    local procedure FillPaymentServiceRowPart(var TempPaymentReportingArgument: Record "Payment Reporting Argument" temporary; PaymentServiceRowHTMLText: Text) PaymentServiceHTMLText: Text
    var
        PaymentServiceUrl: Text;
    begin
        PaymentServiceHTMLText := PaymentServiceRowHTMLText;
        PaymentServiceUrl := TempPaymentReportingArgument.GetTargetURL;
        FillParameterValueEncoded(PaymentServiceHTMLText, 'PaymentServiceUrl', PaymentServiceUrl);
        FillParameterValueEncoded(PaymentServiceHTMLText, 'PaymentServiceAlt', TempPaymentReportingArgument."URL Caption");
        FillParameterValue(PaymentServiceHTMLText, 'PaymentServiceLogo',
          GetPaymentServiceLogoAsText(TempPaymentReportingArgument));
        FillParameterValueEncoded(PaymentServiceHTMLText, 'PrimaryColor', GetPrimaryColorValue);
    end;

    local procedure MakeFullCompanyAddress(CompanyAddr: array[8] of Text[100]) FullCompanyAddress: Text
    var
        i: Integer;
    begin
        FullCompanyAddress := CompanyAddr[2];
        for i := 3 to 8 do begin
            if CompanyAddr[i] <> '' then
                FullCompanyAddress += ', ' + CompanyAddr[i];
        end;
    end;

    local procedure MakeParameterNameString(ParameterName: Text): Text
    begin
        exit(StrSubstNo('<!--%1-->', ParameterName));
    end;

    local procedure ReplaceHTMLText(var HTMLText: Text; OldValue: Text; NewValue: Text)
    var
        Regex: DotNet Regex;
    begin
        Regex := Regex.Regex(OldValue);
        if Regex.IsMatch(HTMLText) then
            HTMLText := Regex.Replace(HTMLText, NewValue);
    end;

    [Scope('OnPrem')]
    procedure ReplaceBodyFileSendTo(BodyFileName: Text; OldSendTo: Text; NewSendTo: Text)
    var
        InStream: InStream;
        BodyFile: File;
        HTMLText: Text;
        Buffer: Text;
    begin
        BodyFile.Open(BodyFileName, TEXTENCODING::UTF8);
        BodyFile.CreateInStream(InStream);
        while not InStream.EOS do begin
            InStream.Read(Buffer);
            HTMLText += Buffer;
        end;
        BodyFile.Close;

        ReplaceHTMLText(HTMLText, OldSendTo, NewSendTo);
        SaveHTML(BodyFileName, HTMLText);
    end;

    procedure SaveHTML(OutputFileName: Text; HTMLText: Text)
    var
        OutStream: OutStream;
        OutputFile: File;
    begin
        OutputFile.WriteMode(true);
        OutputFile.Create(OutputFileName, TEXTENCODING::UTF8);
        OutputFile.CreateOutStream(OutStream);
        OutStream.Write(HTMLText, StrLen(HTMLText));
        OutputFile.Close;
    end;

    local procedure SliceSalesCoverLetterTemplate(var HTMLText: Text; var PaymentServicesSectionHTMLText: Text; var PaymentServiceRowHTMLText: Text; var SocialNetworksSectionHTMLText: Text; var SocialNetworkRowSectionHTMLText: Text)
    begin
        SliceSection(HTMLText, PaymentServicesSectionHTMLText, 'PaymentSevicesSection', 'PaymentSevices');
        SliceSection(PaymentServicesSectionHTMLText, PaymentServiceRowHTMLText, 'PaymentServiceRowSection', 'PaymentServicesRows');
        SliceSection(HTMLText, SocialNetworksSectionHTMLText, 'SocialNetworksSection', 'SocialNetworks');
        SliceSection(SocialNetworksSectionHTMLText, SocialNetworkRowSectionHTMLText, 'SocialNetworkRowSection', 'CoverLetterSocialRow');
    end;

    local procedure SliceSection(var HTMLText: Text; var SectionHTMLText: Text; SectionName: Text; SectionHolderName: Text)
    var
        StartPosition: Integer;
        EndPosition: Integer;
        StartSectionParameter: Text;
        EndSectionParameter: Text;
        SectionHolderParameter: Text;
    begin
        StartSectionParameter := MakeParameterNameString(StrSubstNo('%1.Start', SectionName));
        EndSectionParameter := MakeParameterNameString(StrSubstNo('%1.End', SectionName));
        SectionHolderParameter := MakeParameterNameString(SectionHolderName);

        StartPosition := StrPos(HTMLText, StartSectionParameter);
        EndPosition := StrPos(HTMLText, EndSectionParameter);

        SectionHTMLText :=
          CopyStr(
            HTMLText,
            StartPosition + StrLen(StartSectionParameter) + 1,
            EndPosition - StartPosition - StrLen(StartSectionParameter) - 1);

        HTMLText :=
          CopyStr(HTMLText, 1, StartPosition - 1) +
          SectionHolderParameter +
          CopyStr(HTMLText, EndPosition + StrLen(EndSectionParameter));
    end;

    local procedure EncodeMessage(Message: Text; CarriageReturn: Boolean): Text
    var
        TypeHelper: Codeunit "Type Helper";
        String: DotNet String;
        NewLineChar: Char;
        CarriageReturnChar: Char;
    begin
        if Message = '' then
            exit('');

        String := TypeHelper.HtmlEncode(Message);

        NewLineChar := 10;
        CarriageReturnChar := 13;
        if CarriageReturn then
            exit(String.Replace(Format(CarriageReturnChar) + Format(NewLineChar), '<br />'));
        exit(String.Replace(Format(NewLineChar), '<br />'));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResizeCompanyLogo(var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    local procedure ResizePaymentServiceLogoIfNeeded(var TempBlob: Codeunit "Temp Blob")
    var
        ImageHandlerManagement: Codeunit "Image Handler Management";
        ImageWidth: Integer;
        ImageHeight: Integer;
        AdvisedImageHeightPixels: Integer;
    begin
        AdvisedImageHeightPixels := 35;

        if ImageHandlerManagement.GetImageSizeBlob(TempBlob, ImageWidth, ImageHeight) then
            if ImageHeight > AdvisedImageHeightPixels then
                if ImageHandlerManagement.ScaleDownFromBlob(TempBlob, ImageWidth, AdvisedImageHeightPixels) then;
    end;
}

