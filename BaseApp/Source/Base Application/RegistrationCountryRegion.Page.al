page 11762 "Registration Country/Region"
{
    Caption = 'Registration Country/Region';
    DataCaptionFields = "Account No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Registration Country/Region";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';

    layout
    {
        area(content)
        {
            repeater(Control1220014)
            {
                ShowCaption = false;
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of issued payment order lines';
                    Visible = false;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer or vendor.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        VATRegistrationLogMgt.AssistEditRegCountryRegionVATReg(Rec);
                    end;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a VAT business posting group code.';
                    Visible = VATBusPostingGroupVisible;
                }
                field("Currency Code (Local)"; "Currency Code (Local)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the local currency code.';
                    Visible = CurrencyCodeLocalVisible;
                }
                field("VAT Rounding Type"; "VAT Rounding Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the VAT rounding type is nearest (Nearest) or up (Up) or down (Down).';
                    Visible = VATRoundingTypeVisible;
                }
                field("Rounding VAT"; "Rounding VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the size of the interval to be used when rounding VAT.';
                    Visible = RoundingVATVisible;
                }
                field("Intrastat Export Object Type"; "Intrastat Export Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of intrastat export object.';
                    Visible = false;
                }
                field("Intrastat Export Object No."; "Intrastat Export Object No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of intrastat export object.';
                    Visible = false;
                }
                field("Intrastat Exch.Rate Mandatory"; "Intrastat Exch.Rate Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibility to select intrastat exchange rate.';
                }
                field("VIES Decl. Exp. Obj. Type"; "VIES Decl. Exp. Obj. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object type for VIES declaration export.';
                    Visible = false;
                }
                field("VIES Decl. Exp. Obj. No."; "VIES Decl. Exp. Obj. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object number for VIES declaration export.';
                    Visible = false;
                }
                field("VIES Decl. Exp. Obj. Name"; "VIES Decl. Exp. Obj. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object name for VIES declaration export.';
                    Visible = false;
                }
                field("VIES Declaration Report No."; "VIES Declaration Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object number for VIES declaration report.';
                    Visible = false;
                }
                field("VIES Declaration Report Name"; "VIES Declaration Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object name for VIES declaration report.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220000; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220001; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Check VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check VAT Registration No.';
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Verify a Tax registration number.';

                    trigger OnAction()
                    begin
                        VerifyFromVIES;
                    end;
                }
                action("Registration Country Routes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Registration Country Routes';
                    Image = List;
                    RunObject = Page "Registr. Country/Region Routes";
                    RunPageLink = "Perform. Country/Region Code" = FIELD("Country/Region Code");
                    ToolTip = 'Specifies registration country routes for the registration country';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this action should not be used. (Obsolete::Removed in release 01.2021)';
                }
            }
        }
    }

    trigger OnInit()
    begin
        RoundingVATVisible := true;
        VATRoundingTypeVisible := true;
        CurrencyCodeLocalVisible := true;
        VATBusPostingGroupVisible := true;
    end;

    trigger OnOpenPage()
    begin
        if ("Account Type" = "Account Type"::"Company Information") and ("Account No." = '') then begin
            VATBusPostingGroupVisible := false;
            CurrencyCodeLocalVisible := true;
            VATRoundingTypeVisible := true;
            RoundingVATVisible := true;
        end;

        if ("Account Type" <> "Account Type"::"Company Information") and ("Account No." <> '') then begin
            VATBusPostingGroupVisible := true;
            CurrencyCodeLocalVisible := false;
            VATRoundingTypeVisible := false;
            RoundingVATVisible := false;
        end;
    end;

    var
        [InDataSet]
        VATBusPostingGroupVisible: Boolean;
        [InDataSet]
        CurrencyCodeLocalVisible: Boolean;
        [InDataSet]
        VATRoundingTypeVisible: Boolean;
        [InDataSet]
        RoundingVATVisible: Boolean;
}

