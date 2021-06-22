page 2142 "O365 First Invoice Wizard"
{
    Caption = ' ';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND CustomerStepVisible;
                field("MediaResourcesFirstInv1.""Media Reference"""; MediaResourcesFirstInv1."Media Reference")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND ItemStepVisible;
                field("MediaResourcesFirstInv2.""Media Reference"""; MediaResourcesFirstInv2."Media Reference")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control42)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND TaxStepVisible;
                field("MediaResourcesFirstInv3.""Media Reference"""; MediaResourcesFirstInv3."Media Reference")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(FirstStep)
            {
                Visible = FirstStepVisible;
                group(Hi)
                {
                    Caption = 'Hi';
                    Visible = NOT UserNameAvailable;
                }
                group("Hi,")
                {
                    Caption = 'Hi,';
                    Visible = UserNameAvailable;
                    field(UserName; UserName)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'User';
                        Editable = false;
                        ShowCaption = false;

                        trigger OnValidate()
                        begin
                            EnableControls;
                        end;
                    }
                }
                group(Control30)
                {
                    Editable = false;
                    ShowCaption = false;
                    Visible = ImagesVisible;
                    field("<MediaRepositoryFirstInvFirst>"; MediaResourcesFirstInvFirst."Media Reference")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = '<MediaRepositoryFirstInvFirst>';
                        Editable = false;
                        ShowCaption = false;
                    }
                }
                group(Control19)
                {
                    InstructionalText = 'Let''s create your first invoice.';
                    ShowCaption = false;
                }
            }
            group(CustomerStep)
            {
                Visible = CustomerStepVisible;
                group("Who are you invoicing?")
                {
                    Caption = 'Who are you invoicing?';
                    group(Control18)
                    {
                        InstructionalText = 'We''ll file this away for next time.';
                        ShowCaption = false;
                        field(CustomerName; CustomerName)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'Customer name';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                ModifyCustomer;
                                EnableControls;
                            end;
                        }
                        field(CustomerEmail; CustomerEmail)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'Email (optional)';
                            ExtendedDatatype = EMail;
                            ShowCaption = false;

                            trigger OnValidate()
                            var
                                MailManagement: Codeunit "Mail Management";
                            begin
                                if CustomerEmail <> '' then
                                    MailManagement.CheckValidEmailAddress(CustomerEmail);
                                ModifyCustomer;
                                EnableControls;
                            end;
                        }
                        field("<FullAddress>"; FullAddress)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'Address (optional)';
                            QuickEntry = false;
                            ShowCaption = false;

                            trigger OnAssistEdit()
                            var
                                TempStandardAddress: Record "Standard Address" temporary;
                            begin
                                CreateCustomer(CustomerName);
                                TempStandardAddress.CopyFromCustomer(Customer);
                                if PAGE.RunModal(PAGE::"O365 Address", TempStandardAddress) = ACTION::LookupOK then begin
                                    Customer.Get(Customer."No.");
                                    FullAddress := TempStandardAddress.ToString;
                                end;
                            end;
                        }
                    }
                }
            }
            group(ItemStep)
            {
                Visible = ItemStepVisible;
                group("What did you sell?")
                {
                    Caption = 'What did you sell?';
                    group(Control2)
                    {
                        InstructionalText = 'Start adding items. You can always edit later.';
                        ShowCaption = false;
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'Description of product or service';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                EnableControls;
                            end;
                        }
                        field(ItemPrice; ItemPrice)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            BlankZero = true;
                            Caption = 'Price (excl. tax)';
                            DecimalPlaces = 2 : 5;
                            MinValue = 0;
                            ShowCaption = false;
                        }
                    }
                }
            }
            group(TaxStep)
            {
                Visible = TaxStepVisible;
                group("Need to add sales tax?")
                {
                    Caption = 'Need to add sales tax?';
                    Visible = NOT IsUsingVAT;
                    group(Control17)
                    {
                        InstructionalText = 'Tell us the tax rate for your region.';
                        ShowCaption = false;
                        Visible = NOT IsUsingVAT;
                        field(CityTax; CityTax)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            BlankZero = true;
                            Caption = 'City Tax %';
                            DecimalPlaces = 1 : 3;
                            MinValue = 0;
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                EnableControls;
                            end;
                        }
                        field(StateTax; StateTax)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            BlankZero = true;
                            Caption = 'State Tax %';
                            DecimalPlaces = 1 : 3;
                            MinValue = 0;
                            ShowCaption = false;
                        }
                    }
                }
                group("Here is your default VAT.")
                {
                    Caption = 'Here is your default VAT.';
                    Visible = IsUsingVAT;
                    group(Control21)
                    {
                        InstructionalText = 'You can always edit it later.';
                        ShowCaption = false;
                        Visible = IsUsingVAT;
                        field("VAT Group"; VATProductPostingGroup.Description)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'VAT';
                            NotBlank = true;
                            QuickEntry = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the VAT group code for this item.';
                            Visible = IsUsingVAT;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if PAGE.RunModal(PAGE::"O365 VAT Product Posting Gr.", VATProductPostingGroup) = ACTION::LookupOK then;
                            end;
                        }
                    }
                }
            }
            group(FinalStep)
            {
                Visible = FinalStepVisible;
                group(Control20)
                {
                    Editable = false;
                    ShowCaption = false;
                    Visible = ImagesVisible;
                    field("<MediaRepositoryLastInvFirst>"; MediaResourcesFirstInvLast."Media Reference")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = '<MediaRepositoryLastInvFirst>';
                        Editable = false;
                        ShowCaption = false;
                    }
                }
                group("Voila!")
                {
                    Caption = 'Voila!';
                    group(Control46)
                    {
                        InstructionalText = 'Your first invoice is ready. Preview it, send it, or add more details whenever you want.';
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Next';
                Image = NextRecord;
                InFooterBar = true;
                Visible = NextActionEnabled;

                trigger OnAction()
                begin
                    NextStep;
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Back';
                Image = PreviousRecord;
                InFooterBar = true;
                Visible = BackActionEnabled;

                trigger OnAction()
                begin
                    PrevStep;
                end;
            }
            action(ActionCreateInvoice)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Create Invoice';
                InFooterBar = true;
                Visible = CreateInvoiceActionEnabled;

                trigger OnAction()
                begin
                    Step := Step::Customer;
                    EnableControls;
                end;
            }
            action(ActionDone)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Done';
                InFooterBar = true;
                Visible = DoneActionEnabled;

                trigger OnAction()
                begin
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Initialize
    end;

    trigger OnOpenPage()
    begin
        Step := Step::First;
        EnableControls;

        ItemBaseUnitOfMeasure := O365TemplateManagement.GetDefaultBaseUnitOfMeasure;

        if IsUsingVAT then begin
            VATBusinessPostingGroupCode := O365TemplateManagement.GetDefaultVATBusinessPostingGroup;
            VATProductPostingGroup.Get(O365TemplateManagement.GetDefaultVATProdPostingGroup);
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Customer."No." <> '' then
            if Step <> Step::Finish then
                Customer.Delete(true);
    end;

    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        MediaRepositoryFirstInv1: Record "Media Repository";
        MediaRepositoryFirstInv2: Record "Media Repository";
        MediaRepositoryFirstInv3: Record "Media Repository";
        MediaRepositoryFirstInvFirst: Record "Media Repository";
        MediaRepositoryFirstInvLast: Record "Media Repository";
        MediaResourcesFirstInv1: Record "Media Resources";
        MediaResourcesFirstInv2: Record "Media Resources";
        MediaResourcesFirstInv3: Record "Media Resources";
        MediaResourcesFirstInvFirst: Record "Media Resources";
        MediaResourcesFirstInvLast: Record "Media Resources";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        O365TemplateManagement: Codeunit "O365 Template Management";
        Step: Option First,Customer,Item,Tax,Finish;
        TopBannerVisible: Boolean;
        ImagesVisible: Boolean;
        FirstStepVisible: Boolean;
        CustomerStepVisible: Boolean;
        ItemStepVisible: Boolean;
        TaxStepVisible: Boolean;
        FinalStepVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        CreateInvoiceActionEnabled: Boolean;
        DoneActionEnabled: Boolean;
        UserNameAvailable: Boolean;
        UserName: Text;
        CustomerName: Text[100];
        ItemDescription: Text[100];
        FullAddress: Text;
        ItemPrice: Decimal;
        ItemBaseUnitOfMeasure: Code[10];
        CityTax: Decimal;
        StateTax: Decimal;
        VATBusinessPostingGroupCode: Code[20];
        IsUsingVAT: Boolean;
        ItemNoDescriptionErr: Label 'Give your product or service a description.';
        CustNoNameErr: Label 'Enter a customer name to create your first invoice for them.';
        CustomerEmail: Text[80];

    procedure HasCompleted(): Boolean
    begin
        exit(Step = Step::Finish);
    end;

    procedure GetInvoiceNo(): Code[20]
    begin
        exit(SalesHeader."No.");
    end;

    local procedure EnableControls()
    begin
        ResetControls;

        case Step of
            Step::First:
                ShowFirstStep;
            Step::Customer:
                ShowCustomerStep;
            Step::Item:
                ShowItemStep;
            Step::Tax:
                ShowTaxStep;
            Step::Finish:
                ShowFinishStep;
        end;
    end;

    local procedure PrevStep()
    begin
        case Step of
            Step::First:
                ShowFirstStep;
            Step::Customer:
                ShowFirstStep;
            Step::Item:
                ShowCustomerStep;
            Step::Tax:
                ShowItemStep;
            Step::Finish:
                ShowFinishStep;
        end;
        EnableControls;
    end;

    local procedure NextStep()
    begin
        case Step of
            Step::First:
                ShowCustomerStep;
            Step::Customer:
                if ValidateCustomer then
                    ShowItemStep;
            Step::Item:
                if ValidateItem then
                    ShowTaxStep;
            Step::Tax:
                ShowFinishStep;
        end;
        EnableControls;
    end;

    local procedure ShowFirstStep()
    begin
        Step := Step::First;
        FirstStepVisible := true;
        CreateInvoiceActionEnabled := true;
    end;

    local procedure ShowCustomerStep()
    begin
        Step := Step::Customer;
        CustomerStepVisible := true;
        NextActionEnabled := true;
        BackActionEnabled := true;
    end;

    local procedure ShowItemStep()
    begin
        Step := Step::Item;
        ItemStepVisible := true;
        NextActionEnabled := true;
        BackActionEnabled := true;
    end;

    local procedure ShowTaxStep()
    begin
        Step := Step::Tax;
        TaxStepVisible := true;
        NextActionEnabled := true;
        BackActionEnabled := true;
    end;

    local procedure ShowFinishStep()
    begin
        CreateInvoice;
        Step := Step::Finish;
        FinalStepVisible := true;
        DoneActionEnabled := true;
    end;

    local procedure ResetControls()
    begin
        NextActionEnabled := false;
        FirstStepVisible := false;
        CustomerStepVisible := false;
        ItemStepVisible := false;
        TaxStepVisible := false;
        FinalStepVisible := false;
        BackActionEnabled := false;
        DoneActionEnabled := false;
        CreateInvoiceActionEnabled := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryFirstInv1.Get('FirstInvoice1.png', 'PHONE') and
           MediaRepositoryFirstInv2.Get('FirstInvoice2.png', 'PHONE') and
           MediaRepositoryFirstInv3.Get('FirstInvoice3.png', 'PHONE')
        then
            if MediaResourcesFirstInv1.Get(MediaRepositoryFirstInv1."Media Resources Ref") and
               MediaResourcesFirstInv2.Get(MediaRepositoryFirstInv2."Media Resources Ref") and
               MediaResourcesFirstInv3.Get(MediaRepositoryFirstInv3."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesFirstInv1."Media Reference".HasValue;
    end;

    local procedure LoadImages()
    begin
        if MediaRepositoryFirstInvFirst.Get('FirstInvoiceSplash.png', 'PHONE') and
           MediaRepositoryFirstInvLast.Get('FirstInvoiceSplash.png', 'PHONE')
        then
            if MediaResourcesFirstInvFirst.Get(MediaRepositoryFirstInvFirst."Media Resources Ref") and
               MediaResourcesFirstInvLast.Get(MediaRepositoryFirstInvLast."Media Resources Ref")
            then
                ImagesVisible := MediaResourcesFirstInvFirst."Media Reference".HasValue;
    end;

    local procedure CreateCustomer(CustomerName: Text[100])
    var
        Customer2: Record Customer;
        MiniCustomerTemplate: Record "Mini Customer Template";
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        if Customer."No." <> '' then
            exit;

        Customer2.Init();
        if MiniCustomerTemplate.NewCustomerFromTemplate(Customer2) then begin
            Customer2.Validate(Name, CustomerName);
            Customer2.Validate("E-Mail", CustomerEmail);
            Customer2.Validate("Tax Liable", true);
            Customer2.Modify(true);
            CustContUpdate.OnModify(Customer2);
            Commit();
        end;

        Customer := Customer2;
    end;

    local procedure CreateItem()
    var
        ItemTemplate: Record "Item Template";
    begin
        if Item."No." = '' then begin
            Item.Init();
            if ItemTemplate.NewItemFromTemplate(Item) then begin
                Item.Validate(Description, ItemDescription);
                Item.Validate("Unit Price", ItemPrice);
                if IsUsingVAT then
                    Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                if ItemBaseUnitOfMeasure <> '' then
                    Item.Validate("Base Unit of Measure", ItemBaseUnitOfMeasure);
                Item.Modify(true);
                Commit();
            end;
        end;
    end;

    local procedure CreateInvoice()
    begin
        if SalesHeader."No." <> '' then
            exit;
        CreateCustomer(CustomerName);
        CreateItem;
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify();

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Insert(true);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        if IsUsingVAT then begin
            SalesLine."VAT Bus. Posting Group" := VATBusinessPostingGroupCode;
            SalesLine."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        end;
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify();
    end;

    local procedure ValidateItem(): Boolean
    begin
        if ItemDescription = '' then
            Error(ItemNoDescriptionErr);

        exit(true);
    end;

    local procedure ValidateCustomer(): Boolean
    begin
        if CustomerName = '' then
            Error(CustNoNameErr);

        exit(true);
    end;

    local procedure Initialize()
    begin
        LoadTopBanners;
        LoadImages;
        GetUserFirstName;
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
    end;

    local procedure GetUserFirstName()
    var
        User: Record User;
        TempString: Text;
    begin
        if User.Get(UserSecurityId) then begin
            TempString := User."Full Name";
            TempString := DelChr(TempString, '<>', ' ');
            TempString := ConvertStr(TempString, ' ', ',');
            UserName := SelectStr(1, TempString);
            if UserName <> '' then
                UserNameAvailable := true;
        end;
    end;

    local procedure ModifyCustomer()
    var
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        if Customer."No." <> '' then begin
            Customer.Validate(Name, CustomerName);
            Customer.Validate("E-Mail", CustomerEmail);
            Customer.Modify(true);
            CustContUpdate.OnModify(Customer);
        end;
    end;
}

