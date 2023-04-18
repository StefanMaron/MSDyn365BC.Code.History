table 2132 "O365 Settings Menu"
{
    Caption = 'O365 Settings Menu';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Key';
        }
        field(2; "Page ID"; Integer)
        {
            Caption = 'Page ID';
        }
        field(3; Title; Text[30])
        {
            Caption = 'Title';
        }
        field(4; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; Link; Text[250])
        {
            Caption = 'Link';
            ExtendedDatatype = URL;
        }
        field(6; "On Open Action"; Option)
        {
            Caption = 'On Open Action';
            OptionCaption = 'Hyperlink,Page';
            OptionMembers = Hyperlink,"Page";
        }
        field(10; Parameter; Text[250])
        {
            Caption = 'Parameter';
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN21
    trigger OnInsert()
    begin
        Key := Key + 1;
    end;

    var
        UnexpectedParemeterErr: Label 'Unexpected parameter: %1.', Comment = '%1 - the parameter''s value';

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure OpenPage()
    begin
        if Parameter <> '' then
            OpenPageWithParameter()
        else
            PAGE.Run("Page ID");
    end;

    local procedure OpenPageWithParameter()
    begin
        case "Page ID" of
            PAGE::"O365 Import from Excel Wizard":
                OpenImportFromExcelWizard();
            else
                Error(UnexpectedParemeterErr, Parameter);
        end;
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure OpenLink()
    begin
        HyperLink(Link);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure InsertPageMenuItem(PageIDValue: Integer; TitleValue: Text[30]; DescriptionValue: Text[80])
    begin
        "Page ID" := PageIDValue;
        Title := TitleValue;
        Description := DescriptionValue;
        "On Open Action" := "On Open Action"::Page;
        Insert(true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure InsertPageWithParameterMenuItem(PageIDValue: Integer; PageParameter: Text[250]; TitleValue: Text[30]; DescriptionValue: Text[80])
    begin
        "Page ID" := PageIDValue;
        Parameter := PageParameter;
        Title := TitleValue;
        Description := DescriptionValue;
        "On Open Action" := "On Open Action"::Page;
        Insert(true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure InsertHyperlinkMenuItem(HyperlinkValue: Text[250]; TitleValue: Text[30]; DescriptionValue: Text[80])
    begin
        Link := HyperlinkValue;
        Title := TitleValue;
        Description := DescriptionValue;
        "On Open Action" := "On Open Action"::Hyperlink;
        Insert(true);
    end;

    local procedure OpenImportFromExcelWizard()
    var
        DummyCustomer: Record Customer;
        DummyItem: Record Item;
        O365ImportFromExcelWizard: Page "O365 Import from Excel Wizard";
    begin
        case Parameter of
            DummyCustomer.TableName:
                O365ImportFromExcelWizard.PrepareCustomerImportData();
            DummyItem.TableName:
                O365ImportFromExcelWizard.PrepareItemImportData();
            else
                Error(UnexpectedParemeterErr, Parameter);
        end;
        O365ImportFromExcelWizard.RunModal();
    end;
#endif
}

