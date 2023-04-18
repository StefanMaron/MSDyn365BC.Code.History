page 1340 "Config Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Templates';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Config. Template Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater("Repeater")
            {
                field("Template Name"; Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies a description of the template.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies if the template is ready to be used';
                    Visible = NOT NewMode;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(NewConfigTemplate)
            {
                ApplicationArea = All;
                Caption = 'New';
                Image = New;
                RunObject = Page "Config. Template Header";
                RunPageMode = Create;
                ToolTip = 'Create a new configuration template.';
            }
        }
        area(processing)
        {
            action(Delete)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    if Confirm(StrSubstNo(DeleteQst, Code)) then
                        Delete(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(NewConfigTemplate_Promoted; NewConfigTemplate)
                {
                }
                actionref(Delete_Promoted; Delete)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        case "Table ID" of
            DATABASE::Customer,
          DATABASE::Item:
                ConfigTemplateManagement.DeleteRelatedTemplates(Code, DATABASE::"Default Dimension");
        end;
    end;

    trigger OnOpenPage()
    var
        FilterValue: Text;
    begin
        FilterValue := GetFilter("Table ID");

        if not Evaluate(FilteredTableId, FilterValue) then
            FilteredTableId := 0;

        UpdatePageCaption();

        if NewMode then
            UpdateSelection();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if NewMode and (CloseAction = ACTION::LookupOK) then
            SaveSelection();
    end;

    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        FilteredTableId: Integer;
        ConfigurationTemplatesCap: Label 'Configuration Templates';
        CustomerTemplatesCap: Label 'Customer Templates';
        VendorTemplatesCap: Label 'Vendor Templates';
        ItemTemplatesCap: Label 'Item Templates';
        SelectConfigurationTemplatesCap: Label 'Select a template';
        SelectCustomerTemplatesCap: Label 'Select a template for a new customer';
        SelectVendorTemplatesCap: Label 'Select a template for a new vendor';
        SelectItemTemplatesCap: Label 'Select a template for a new item';
        DeleteQst: Label 'Delete %1?', Comment = '%1 - configuration template code';

    protected var
        NewMode: Boolean;

    local procedure UpdatePageCaption()
    var
        PageCaption: Text;
    begin
        if not NewMode then
            case FilteredTableId of
                DATABASE::Customer:
                    PageCaption := CustomerTemplatesCap;
                DATABASE::Vendor:
                    PageCaption := VendorTemplatesCap;
                DATABASE::Item:
                    PageCaption := ItemTemplatesCap;
                else
                    PageCaption := ConfigurationTemplatesCap;
            end
        else
            case FilteredTableId of
                DATABASE::Customer:
                    PageCaption := SelectCustomerTemplatesCap;
                DATABASE::Vendor:
                    PageCaption := SelectVendorTemplatesCap;
                DATABASE::Item:
                    PageCaption := SelectItemTemplatesCap;
                else
                    PageCaption := SelectConfigurationTemplatesCap;
            end;

        CurrPage.Caption(PageCaption);
    end;

    local procedure UpdateSelection()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        TemplateSelectionMgt: Codeunit "Template Selection Mgt.";
        TemplateCode: Code[10];
    begin
        case FilteredTableId of
            DATABASE::Customer:
                TemplateSelectionMgt.GetLastCustTemplateSelection(TemplateCode);
            DATABASE::Vendor:
                TemplateSelectionMgt.GetLastVendorTemplateSelection(TemplateCode);
            DATABASE::Item:
                TemplateSelectionMgt.GetLastItemTemplateSelection(TemplateCode);
        end;

        if not (TemplateCode = '') then
            if ConfigTemplateHeader.Get(TemplateCode) then
                SetPosition(ConfigTemplateHeader.GetPosition());
    end;

    local procedure SaveSelection()
    var
        TemplateSelectionMgt: Codeunit "Template Selection Mgt.";
    begin
        case FilteredTableId of
            DATABASE::Customer:
                TemplateSelectionMgt.SaveCustTemplateSelectionForCurrentUser(Code);
            DATABASE::Vendor:
                TemplateSelectionMgt.SaveVendorTemplateSelectionForCurrentUser(Code);
            DATABASE::Item:
                TemplateSelectionMgt.SaveItemTemplateSelectionForCurrentUser(Code);
        end;
    end;

    procedure SetNewMode()
    begin
        NewMode := true;
    end;
}

