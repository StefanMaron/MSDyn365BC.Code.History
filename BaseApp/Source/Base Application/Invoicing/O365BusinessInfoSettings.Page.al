#if not CLEAN21
page 2130 "O365 Business Info Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    PageType = CardPart;
    SourceTable = "Company Information";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control18)
            {
                ShowCaption = false;
                group(Control11)
                {
                    InstructionalText = 'Upload your company logo';
                    ShowCaption = false;
                    field(Picture; Picture)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Your logo';
                        ToolTip = 'Specifies your company''s logo.';

                        trigger OnValidate()
                        begin
                            Modify(true);
                        end;
                    }
                }
                group(Control5)
                {
                    ShowCaption = false;
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Company name';
                        Importance = Promoted;
                        NotBlank = true;
                        ToolTip = 'Specifies the name of your company.';
                    }
                    field(BrandColorName; BrandColorName)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Brand color';
                        Editable = false;
                        ToolTip = 'Specifies the brand color code.';

                        trigger OnAssistEdit()
                        var
                            O365BrandColor: Record "O365 Brand Color";
                            O365BrandColors: Page "O365 Brand Colors";
                        begin
                            if O365BrandColor.Get("Brand Color Code") then;

                            O365BrandColors.LookupMode := true;
                            O365BrandColors.SetRecord(O365BrandColor);
                            if O365BrandColors.RunModal() = ACTION::LookupOK then begin
                                O365BrandColors.GetRecord(O365BrandColor);
                                Validate("Brand Color Code", O365BrandColor.Code);
                            end;

                            CurrPage.Update();
                        end;
                    }
                    field(FullAddress; FullAddress)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Address';
                        Editable = false;
                        QuickEntry = false;

                        trigger OnAssistEdit()
                        var
                            TempStandardAddress: Record "Standard Address" temporary;
                        begin
                            CurrPage.SaveRecord();
                            Commit();
                            TempStandardAddress.CopyFromCompanyInformation(Rec);
                            if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                                Get();
                                FullAddress := TempStandardAddress.ToString();
                            end;
                        end;
                    }
                    field("VAT Registration No."; Rec."VAT Registration No.")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'VAT registration number';
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies your company''s email address.';

                        trigger OnValidate()
                        var
                            MailManagement: Codeunit "Mail Management";
                        begin
                            if "E-Mail" <> '' then
                                MailManagement.CheckValidEmailAddress("E-Mail");
                        end;
                    }
                    field("Home Page"; Rec."Home Page")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        ToolTip = 'Specifies your company''s web site.';
                        Visible = false;
                    }
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Phone number';
                        ToolTip = 'Specifies your company''s phone number.';
                    }
                    field(SocialsLink; SocialsLbl)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the links to your company''s social media. We will add these links to the emails you send.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.SaveRecord();
                            Commit();
                            PAGE.RunModal(PAGE::"O365 Social Networks");
                            CurrPage.Update(false);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        TempStandardAddress: Record "Standard Address" temporary;
    begin
        TempStandardAddress.CopyFromCompanyInformation(Rec);
        FullAddress := TempStandardAddress.ToString();

        GetOrSetBrandColor();
    end;

    trigger OnInit()
    begin
        Initialize();
    end;

    var
        FullAddress: Text;
        SocialsLbl: Label 'Social networks';
        BrandColorName: Text;

    local procedure Initialize()
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    local procedure GetOrSetBrandColor()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        if not O365BrandColor.Get("Brand Color Code") then
            if O365BrandColor.FindFirst() then
                Validate("Brand Color Code", O365BrandColor.Code);

        BrandColorName := O365BrandColor.Name;
    end;
}
#endif
