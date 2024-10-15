page 31066 "VIES Declaration"
{
    Caption = 'VIES Declaration (Obsolete)';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "VIES Declaration Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the VIES Declaration.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Declaration Period"; "Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies declaration Period (month, quarter).';
                }
                field("Declaration Type"; "Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the declaration type for the declaration header (normal, corrective, corrective-supplementary).';

                    trigger OnValidate()
                    begin
                        if xRec."Declaration Type" <> "Declaration Type" then
                            if "Declaration Type" <> "Declaration Type"::Corrective then
                                "Corrected Declaration No." := '';
                        DeclarationTypeOnAfterValidate;
                    end;
                }
                field("Corrected Declaration No."; "Corrected Declaration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = CorrectedDeclarationNoEditable;
                    ToolTip = 'Specifies the existing VIES declaration that needs to be corrected.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = NameEditable;
                    ToolTip = 'Specifies the name of VIES declaration.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "VATRegNoEditable";
                    ShowMandatory = true;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                }
                field("Tax Office Number"; "Tax Office Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax office number for reporting.';
                }
                field("Tax Office Region Number"; "Tax Office Region Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax office region number for reporting.';
                }
                field("Trade Type"; "Trade Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "TradeTypeEditable";
                    ToolTip = 'Specifies trade type for the declaration header (sales, purchases or both).';
                }
                field("EU Goods/Services"; "EU Goods/Services")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "EUGoodsServicesEditable";
                    ToolTip = 'Specifies goods, services, or both. The EU requires this information for VIES reporting.';
                }
                field("Company Trade Name Appendix"; "Company Trade Name Appendix")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = CompanyTradeNameAppendixEditab;
                    ToolTip = 'Specifies type of the company.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Period No."; "Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = "PeriodNoEditable";
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the VAT period.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = YearEditable;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the financial year.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration start date. The field is calculated based on the Trade Type, Period No., and financial Year.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies end date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Number of Supplies"; "Number of Supplies")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the number of supplies.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the declaration. The field will display either a status of open or released.';
                }
                field("Taxpayer Type"; "Taxpayer Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies tax payer type.';

                    trigger OnValidate()
                    begin
                        TaxpayerTypeOnAfterValidate;
                    end;
                }
            }
            part(Control1220013; "VIES Declaration Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "VIES Declaration No." = FIELD("No.");
                UpdatePropagation = Both;
            }
            group(Address)
            {
                Caption = 'Address';
                field("Country/Region Name"; "Country/Region Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country for the tax office.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city for the tax office.';
                }
                field(Street; Street)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the street for the tax office.';
                }
                field("House No."; "House No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s house number.';
                }
                field("Municipality No."; "Municipality No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the municipality number fot the tax office that receives the VIES declaration.';
                }
                field("Apartment No."; "Apartment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies apartment number.';
                }
            }
            group(Persons)
            {
                Caption = 'Persons';
                field("Authorized Employee No."; "Authorized Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies authorized employee.';
                }
                field("Filled by Employee No."; "Filled by Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee number for the employee who filled the declaration.';
                }
                field("Natural Employee No."; "Natural Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "NaturalEmplNoEditable";
                    ToolTip = 'Specifies employee number for the natural employee.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("L&ines")
            {
                Caption = 'L&ines';
                action("&Suggest Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'This batch job creates VIES declaration lines from declaration header information and data stored in VAT tables.';

                    trigger OnAction()
                    begin
                        TestField(Status, Status::Open);
                        VIESDeclarationHdr.SetRange("No.", "No.");
                        REPORT.RunModal(REPORT::"Suggest VIES Declaration Lines", true, false, VIESDeclarationHdr);
                    end;
                }
                action("&Get Lines for Correction")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Get Lines for Correction';
                    Ellipsis = true;
                    Image = GetLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'This batch job allows to upload the lines for corrections VIES declaration.';

                    trigger OnAction()
                    var
                        VIESDeclarationLines: Page "VIES Declaration Lines";
                    begin
                        TestField(Status, Status::Open);
                        TestField("Corrected Declaration No.");
                        VIESDeclarationLines.SetToDeclaration(Rec);
                        VIESDeclarationLines.LookupMode := true;
                        if VIESDeclarationLines.RunModal = ACTION::LookupOK then
                            VIESDeclarationLines.CopyLineToDeclaration;

                        Clear(VIESDeclarationLines);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release reverse charge';

                    trigger OnAction()
                    begin
                        ReleaseVIESDeclaration.Run(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = Replan;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have tha Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    begin
                        ReleaseVIESDeclaration.Reopen(Rec);
                    end;
                }
                action("&Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export';
                    Image = Export;
                    ToolTip = 'This batch job exported VIES declaration results in XML format.';

                    trigger OnAction()
                    begin
                        Export;
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Test Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Report';
                Ellipsis = true;
                Image = TestReport;
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'Specifies test report';

                trigger OnAction()
                begin
                    PrintTestReport;
                end;
            }
            action("&Declaration")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Declaration';
                Image = "Report";
                ToolTip = 'This batch job exported VIES declaration results in XML format.';

                trigger OnAction()
                begin
                    Print;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetControlsEditable;
    end;

    trigger OnInit()
    begin
        NaturalEmplNoEditable := true;
        CompanyTradeNameAppendixEditab := true;
        EUGoodsServicesEditable := true;
        TradeTypeEditable := true;
        VATRegNoEditable := true;
        NameEditable := true;
        YearEditable := true;
        PeriodNoEditable := true;
        CorrectedDeclarationNoEditable := true;
    end;

    trigger OnOpenPage()
    begin
        SetDocNoVisible;
    end;

    var
        VIESDeclarationHdr: Record "VIES Declaration Header";
        ReleaseVIESDeclaration: Codeunit "Release VIES Declaration";
        [InDataSet]
        CorrectedDeclarationNoEditable: Boolean;
        [InDataSet]
        PeriodNoEditable: Boolean;
        [InDataSet]
        YearEditable: Boolean;
        [InDataSet]
        NameEditable: Boolean;
        [InDataSet]
        VATRegNoEditable: Boolean;
        [InDataSet]
        TradeTypeEditable: Boolean;
        [InDataSet]
        EUGoodsServicesEditable: Boolean;
        [InDataSet]
        CompanyTradeNameAppendixEditab: Boolean;
        [InDataSet]
        NaturalEmplNoEditable: Boolean;
        DocNoVisible: Boolean;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure SetControlsEditable()
    var
        Corrective: Boolean;
    begin
        Corrective := "Declaration Type" in ["Declaration Type"::Corrective,
                                             "Declaration Type"::"Corrective-Supplementary"];
        CorrectedDeclarationNoEditable := Corrective;
        PeriodNoEditable := not Corrective;
        YearEditable := not Corrective;
        NameEditable := not Corrective;
        VATRegNoEditable := not Corrective;
        TradeTypeEditable := not Corrective;
        EUGoodsServicesEditable := not Corrective;
        case "Taxpayer Type" of
            "Taxpayer Type"::Corporation:
                begin
                    NameEditable := true;
                    CompanyTradeNameAppendixEditab := true;
                    NaturalEmplNoEditable := false;
                end;
            "Taxpayer Type"::Individual:
                begin
                    NameEditable := false;
                    CompanyTradeNameAppendixEditab := false;
                    NaturalEmplNoEditable := true;
                end;
        end;
    end;

    local procedure DeclarationTypeOnAfterValidate()
    begin
        SetControlsEditable;
    end;

    local procedure TaxpayerTypeOnAfterValidate()
    begin
        SetControlsEditable;
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option "VIES Declaration","Reverse Charge";
    begin
        DocNoVisible := DocumentNoVisibility.StatReportingDocumentNoIsVisible(DocType::"VIES Declaration", "No.");
    end;
}

