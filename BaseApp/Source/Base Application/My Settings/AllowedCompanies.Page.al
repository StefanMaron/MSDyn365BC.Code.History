#if not CLEAN19
page 9177 "Allowed Companies"
{
    Caption = 'Allowed Companies';
    Editable = false;
    PageType = List;
    SourceTable = Company;
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with page Accessible Companies';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(CompanyDisplayName; Rec."Display Name")
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the display name that is defined for the company. If a display name is not defined, then the company name is used.';
                }
                field("Evaluation Company"; Rec."Evaluation Company")
                {
                    ApplicationArea = All;
                    Caption = 'Evaluation Company';
                    Editable = false;
                    ToolTip = 'Specifies that the company is for trial purposes only, and that a subscription has not been purchased.';
                }
                field(SetupStatus; CompanySetupStatuses.Get(Rec.Name))
                {
                    ApplicationArea = All;
                    Caption = 'Setup Status';
                    ToolTip = 'Specifies the setup status of the company.';

                    trigger OnDrillDown()
                    var
                        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
                    begin
                        AssistedCompanySetupStatus.DrillDownSetupStatus(Rec.Name);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Create New Company")
            {
                AccessByPermission = TableData Company = I;
                ApplicationArea = Basic, Suite;
                Caption = 'Create New Company';
                Image = Company;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Get assistance with creating a new company.';
                Visible = SoftwareAsAService;

                trigger OnAction()
                begin
                    // Action invoked through event subscriber to avoid hard coupling to other objects,
                    // as this page is part of the Cloud Manager.
                    Initialize();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if CompanySetupStatuses.Get(Rec.Name) = Enum::"Company Setup Status"::"In Progress" then
            NameStyleExpr := 'Subordinate'
        else
            NameStyleExpr := '';
    end;

    procedure Initialize()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
        EnvironmentInfo: Codeunit "Environment Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        UserAccountHelper: DotNet NavUserAccountHelper;
        CompanyName: Text;
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaS();

        Rec.DeleteAll();
        foreach CompanyName in UserAccountHelper.GetAllowedCompanies() do
            if Company.Get(CompanyName) then begin
                Rec := Company;
                Rec."Display Name" := CompanyInformationMgt.GetCompanyDisplayNameDefaulted(Rec);
                CompanySetupStatuses.Set(Rec.Name, AssistedCompanySetupStatus.GetCompanySetupStatusValue(Rec.Name));
                Rec.Insert();
            end;
    end;

#if not CLEAN17
    [Obsolete('Function moved to codeunit Company Information Management', '17.0')]
    procedure GetCompanyDisplayNameDefaulted(Company: Record Company): Text[250]
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        Exit(CompanyInformationMgt.GetCompanyDisplayNameDefaulted(Company));
    end;
#endif

    var
        CompanySetupStatuses: Dictionary of [Text, Enum "Company Setup Status"];
        NameStyleExpr: Text;
        SoftwareAsAService: Boolean;
}
#endif
