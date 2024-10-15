report 11309 "VAT Annual Listing - Disk"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Annual Listing - Disk';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("Country/Region Code");
            dataitem(VATloop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemTableView = SORTING("Entry No.");

                    trigger OnAfterGetRecord()
                    begin
                        WBase := WBase + Base;
                        WAmount := WAmount + Amount;
                        IsCreditMemo := IsCreditMemo or (Base > 0);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey(Type, "Bill-to/Pay-to No.", "Country/Region Code", "EU 3-Party Trade", "Posting Date");
                        SetRange(Type, Type::Sale);
                        SetRange("Bill-to/Pay-to No.", VATCustomer."No.");
                        SetRange("Posting Date", DMY2Date(1, 1, VYear), DMY2Date(31, 12, VYear));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if VATCustomer.Next = 0 then
                        CurrReport.Break();
                    if VATCustomer.Mark then
                        CurrReport.Skip();
                    if not CheckVatNo.MOD97Check(VATCustomer."Enterprise No.") then
                        CurrReport.Skip();
                    VATCustomer.Mark(true);
                end;

                trigger OnPreDataItem()
                var
                    i: Integer;
                begin
                    VATCustomer."Enterprise No." := '';
                    VATCustomer.SetCurrentKey("Enterprise No.");

                    VatRegNoFilter := '*';

                    for i := 1 to StrLen(Customer."Enterprise No.") do begin
                        if Customer."Enterprise No."[i] in ['a' .. 'z', 'A' .. 'Z', '0' .. '9'] then
                            VatRegNoFilter := VatRegNoFilter + CopyStr(Customer."Enterprise No.", i, 1) + '*';
                    end;
                    VATCustomer.SetFilter("Enterprise No.", VatRegNoFilter);

                    if IncludeCountry = IncludeCountry::Specific then
                        VATCustomer.SetRange("Country/Region Code", Country);
                end;
            }
            dataitem(Vatloop2; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

                trigger OnAfterGetRecord()
                var
                    Country2: Record "Country/Region";
                    i: Integer;
                begin
                    i := Buffer.Count + 1;
                    if not SkipMinimumAmount or IsCreditMemo then begin
                        Buffer.Init();
                        Buffer."Entry No." := i;
                        Buffer."Enterprise No." := DelChr(Customer."Enterprise No.", '=', DelChr(Customer."Enterprise No.", '=', '0123456789'));
                        Country2.Get(Customer."Country/Region Code");
                        Buffer."Country/Region Code" := Country2."ISO Code";
                        Buffer.Base := -WBase;
                        Buffer.Amount := -WAmount;
                        Buffer.Insert();
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not SkipMinimumAmount or IsCreditMemo then begin
                        WTotBase2 := WTotBase2 + Buffer.Base;
                        WTotAmount2 := WTotAmount2 + Buffer.Amount;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            var
                EnterpriseNoPrefix: Text[50];
            begin
                if not CheckVatNo.MOD97Check("Enterprise No.") then
                    CurrReport.Skip();

                EnterpriseNoPrefix := UpperCase(DelChr("Enterprise No.", '=', '0123456789,?;.:/-_ '));
                if (StrPos(EnterpriseNoPrefix, 'BTW') = 0) and (StrPos(EnterpriseNoPrefix, 'TVA') = 0) then
                    CurrReport.Skip();

                Clear(WBase);
                Clear(WAmount);
                IsCreditMemo := false;
            end;

            trigger OnPreDataItem()
            begin
                if AddRepresentative then begin
                    Representative.Get(Identifier);
                    Representative.CheckCompletion;
                end;

                if IncludeCountry = IncludeCountry::Specific then
                    SetRange("Country/Region Code", Country);
            end;
        }
        dataitem("Create Intervat XML File"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

            trigger OnAfterGetRecord()
            var
                RunResults: Boolean;
            begin
                RunResults := CreateIntervatXML;

                if SilenceRun and RunResults then
                    exit;

                if not RunResults then
                    Error(Text004);
            end;

            trigger OnPreDataItem()
            begin
                if Buffer.IsEmpty then begin
                    Message(Text009);
                    CurrReport.Quit;
                end;
                InitializeXMLFile;
            end;
        }
    }

    requestpage
    {
        DeleteAllowed = false;
        InsertAllowed = false;
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Control1010020)
                    {
                        ShowCaption = false;
                        field(VYear; VYear)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Year';
                            NotBlank = true;
                            ToolTip = 'Specifies the year of the period for which you want to print the report. You should enter the year as a 4 digit code. For example, to print a declaration for 2013, you should enter "2013" (instead of "13").';

                            trigger OnValidate()
                            begin
                                if not (VYear in [1997 .. 2050]) then
                                    Error(Text002);
                            end;
                        }
                        field(Minimum; Minimum)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Minimum Amount';
                            ToolTip = 'Specifies the minimum customer''s year balance to be included in the report. If the yearly balance of the customer is smaller than the minimum amount, the customer will not be included in the declaration.';
                        }
                        field(TestDeclaration; TestDeclaration)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Test Declaration';
                            ToolTip = 'Specifies if you want to create a test declaration. If selected, an attribute test is written to the file that uses value 1, which indicates that this is a test file. If you want to test the XML file before sending it, you can upload this file to the Intervat site. The file is then validated without being stored on the server and you receive a notification if the file is valid. Also the unique sequence number in the XML file is not increased when a test declaration is created, which means that you can create as many internal test declarations as you want.';
                        }
                    }
                    group("&Representative")
                    {
                        Caption = '&Representative';
                        field(AddRepresentative; AddRepresentative)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Add Representative';
                            ToolTip = 'Specifies if you want to add a VAT declaration representative. A representative is a person or an agency that has license to make a VAT declaration.';

                            trigger OnValidate()
                            begin
                                SetRepresentativeEnabled;
                            end;
                        }
                        field(ID; Identifier)
                        {
                            ApplicationArea = Basic, Suite;
                            Enabled = IDEnable;
                            TableRelation = Representative;
                            ToolTip = 'Specifies the ID of the representative who is responsible for making the VAT declaration.';
                        }
                    }
                    group("Country/Region")
                    {
                        Caption = 'Country/Region';
                        field(IncludeCountry; IncludeCountry)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Customers From';
                            OptionCaption = 'All Countries/Regions,Specific Country/Region';
                            ToolTip = 'Specifies whether to include customers from all countries/regions or from a specific country/region in the report.';
                        }
                        field(Country; Country)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Country/Region';
                            TableRelation = "Country/Region";
                            ToolTip = 'Specifies the country/region to include in the report.';
                        }
                    }
                    label(Control1010019)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19039936;
                        ShowCaption = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            IDEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if VYear = 0 then
                VYear := Date2DMY(WorkDate, 3);
            SetRepresentativeEnabled;

            IncludeCountry := IncludeCountry::Specific;
            Country := INTERVATHelper.GetCpyInfoCountryRegionCode;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if not CheckVatNo.MOD97Check(CompanyInformation."Enterprise No.") then
            Error(Text000, CompanyInformation.FieldCaption("Enterprise No."), CompanyInformation.TableCaption);
        CompanyInformation.TestField("Country/Region Code");
    end;

    trigger OnPreReport()
    begin
        if not AddRepresentative then
            INTERVATHelper.VerifyCpyInfoEmailExists;
    end;

    var
        Text000: Label '%1 in table %2 is not valid.';
        Text002: Label 'Year must be between 1997 and 2050.';
        Text004: Label 'Problem when creating Intervat XML File.';
        VATCustomer: Record Customer;
        Buffer: Record "VAT Entry" temporary;
        Representative: Record Representative;
        CheckVatNo: Codeunit VATLogicalTests;
        INTERVATHelper: Codeunit "INTERVAT Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        WBase: Decimal;
        WAmount: Decimal;
        WTotBase2: Decimal;
        WTotAmount2: Decimal;
        Text009: Label 'No annual sales to export.';
        Minimum: Decimal;
        SilenceRun: Boolean;
        TestDeclaration: Boolean;
        AddRepresentative: Boolean;
        RefreshClientListingsNbr: Boolean;
        FileName: Text;
        VatRegNoFilter: Text[250];
        xmlnsCommon: Text[250];
        xmlnsClientListingConsignment: Text[250];
        VYear: Integer;
        [InDataSet]
        IDEnable: Boolean;
        Text19039936: Label 'The report generates a XML file according to the INTERVAT 8.0 schema defined by the Belgium tax authority.';
        Identifier: Text[20];
        IncludeCountry: Option All,Specific;
        Country: Code[10];
        ClientFileNameTxt: Label 'Intervat.xml', Locked = true;
        IsCreditMemo: Boolean;

    local procedure InitializeXMLFile()
    begin
    end;

    local procedure CreateIntervatXML() ReturnValue: Boolean
    var
        FileManagement: Codeunit "File Management";
        XMLDocOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLFirstNode: DotNet XmlNode;
        ServerFileName: Text;
    begin
        ReturnValue := false;
        RefreshClientListingsNbr := true;

        XMLDOMMgt.LoadXMLDocumentFromText('<ClientListingConsignment/>', XMLDocOut);
        XMLCurrNode := XMLDocOut.DocumentElement;
        INTERVATHelper.AddProcessingInstruction(XMLDocOut, XMLCurrNode);

        AddHeader(XMLCurrNode);
        XMLFirstNode := XMLCurrNode;

        if AddRepresentative then begin
            Representative.AddRepresentativeElement(XMLCurrNode, xmlnsClientListingConsignment, GetClientListingsNbr);
            XMLCurrNode := XMLFirstNode;
        end;

        AddClientListing(XMLCurrNode);

        ServerFileName := FileManagement.ServerTempFileName('.xml');
        XMLDocOut.Save(ServerFileName);
        if FileName = '' then
            FileManagement.DownloadHandler(ServerFileName, '', '', FileManagement.GetToFilterText('', ServerFileName), ClientFileNameTxt)
        else
            FileManagement.CopyServerFile(ServerFileName, FileName, true);
        FileManagement.DeleteServerFile(ServerFileName);

        ReturnValue := true;
    end;

    local procedure AddClientListing(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
        BaseAmount: Text[100];
        VatAmount: Text[100];
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'ClientListing', '', xmlnsClientListingConsignment, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'SequenceNumber', '1');

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'ClientsNbr', Format(Buffer.Count));
        GetAmounts(BaseAmount, VatAmount);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'TurnOverSum', BaseAmount);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'VATAmountSum', VatAmount);

        INTERVATHelper.AddElementDeclarant(XMLCurrNode, GetClientListingsNbr);
        XMLCurrNode := XMLCurrNode.ParentNode;

        XMLDOMMgt.AddElement(XMLCurrNode, 'Period', Format(VYear), xmlnsClientListingConsignment, XMLNewChild);

        AddClientsList(XMLCurrNode);
    end;

    local procedure AddClientsList(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
        CustSequenceNum: Integer;
    begin
        if Buffer.FindSet(true, false) then begin
            repeat
                CustSequenceNum := CustSequenceNum + 1;
                XMLDOMMgt.AddElement(XMLCurrNode, 'Client', '', xmlnsClientListingConsignment, XMLNewChild);
                XMLDOMMgt.AddAttribute(XMLNewChild, 'SequenceNumber', Format(CustSequenceNum));
                XMLCurrNode := XMLNewChild;
                XMLDOMMgt.AddElement(XMLCurrNode, 'CompanyVATNumber', Buffer."Enterprise No.", xmlnsClientListingConsignment, XMLNewChild);
                XMLDOMMgt.AddAttribute(XMLNewChild, 'issuedBy', Buffer."Country/Region Code");
                XMLDOMMgt.AddElement(XMLCurrNode, 'TurnOver', INTERVATHelper.GetXMLAmountRepresentation(Buffer.Base),
                  xmlnsClientListingConsignment, XMLNewChild);
                XMLDOMMgt.AddElement(XMLCurrNode, 'VATAmount', INTERVATHelper.GetXMLAmountRepresentation(Buffer.Amount),
                  xmlnsClientListingConsignment, XMLNewChild);
                XMLCurrNode := XMLCurrNode.ParentNode;
            until Buffer.Next = 0;
        end;
    end;

    local procedure AddHeader(var XMLCurrNode: DotNet XmlNode)
    begin
        xmlnsCommon := 'http://www.minfin.fgov.be/InputCommon';
        xmlnsClientListingConsignment := 'http://www.minfin.fgov.be/ClientListingConsignment';

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'ClientListingsNbr', '1');

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns', 'http://www.minfin.fgov.be/VatList'); // DocNameSpace
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns', xmlnsClientListingConsignment);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:common', xmlnsCommon);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');

        XMLDOMMgt.AddNameSpacePrefixedAttribute(
          XMLCurrNode.OwnerDocument, XMLCurrNode,
          'http://www.w3.org/2001/XMLSchema-instance',
          'schemaLocation',
          xmlnsClientListingConsignment + ' NewLK-in_v0_7.xsd');
    end;

    local procedure GetAmounts(var BaseAmount: Text[100]; var VATAmount: Text[100])
    begin
        BaseAmount := INTERVATHelper.GetXMLAmountRepresentation(WTotBase2);
        VATAmount := INTERVATHelper.GetXMLAmountRepresentation(WTotAmount2);
    end;

    [Scope('OnPrem')]
    procedure InitializeRepresentative(NewAddRepresentative: Boolean)
    begin
        AddRepresentative := NewAddRepresentative;
    end;

    local procedure GetClientListingsNbr(): Integer
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if RefreshClientListingsNbr or TestDeclaration then begin
            CompanyInformation."XML Seq. No. Annual Listing" := CompanyInformation."XML Seq. No. Annual Listing" + 1;
            if CompanyInformation."XML Seq. No. Annual Listing" > 9999 then
                CompanyInformation."XML Seq. No. Annual Listing" := 1;

            if not TestDeclaration then
                CompanyInformation.Modify();

            RefreshClientListingsNbr := false;
        end;

        exit(CompanyInformation."XML Seq. No. Annual Listing");
    end;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure SetRepresentativeEnabled()
    begin
        PageSetRepresentativeEnabled;
    end;

    local procedure SkipMinimumAmount(): Boolean
    begin
        exit((Abs(WBase) < Minimum) and (WBase <= 0));
    end;

    local procedure PageSetRepresentativeEnabled()
    begin
        IDEnable := AddRepresentative;
    end;
}

