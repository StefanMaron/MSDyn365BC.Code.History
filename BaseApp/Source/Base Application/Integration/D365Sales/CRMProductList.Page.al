page 5348 "CRM Product List"
{
    ApplicationArea = Suite;
    Caption = 'Products - Microsoft Dynamics 365 Sales';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Product";
    SourceTableView = SORTING(ProductNumber);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(ProductNumber; ProductNumber)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product Number';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Price; Price)
                {
                    ApplicationArea = Suite;
                    Caption = 'Price';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(StandardCost; StandardCost)
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Cost';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(CurrentCost; CurrentCost)
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Cost';
                    ToolTip = 'Specifies the item''s unit cost.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Products';
                Image = FilterLines;
                ToolTip = 'Do not show coupled products.';

                trigger OnAction()
                begin
                    MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Products';
                Image = ClearFilter;
                ToolTip = 'Show coupled products.';

                trigger OnAction()
                begin
                    MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(ProductId, DATABASE::Item, RecordID) or
           CRMIntegrationRecord.FindRecordIDFromID(ProductId, DATABASE::Resource, RecordID)
        then
            if CurrentlyCoupledCRMProduct.ProductId = ProductId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        FilterGroup(4);
        SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Product"));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMProduct: Record "CRM Product";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMProduct(CRMProduct: Record "CRM Product")
    begin
        CurrentlyCoupledCRMProduct := CRMProduct;
    end;
}

