namespace Microsoft.HumanResources.Setup;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Absence;

table 5218 "Human Resources Setup"
{
    Caption = 'Human Resources Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Employee Nos."; Code[20])
        {
            Caption = 'Employee Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Human Resource Unit of Measure";

            trigger OnValidate()
            var
                EmployeeAbsence: Record "Employee Absence";
                HumanResUnitOfMeasure: Record "Human Resource Unit of Measure";
            begin
                if "Base Unit of Measure" <> xRec."Base Unit of Measure" then
                    if not EmployeeAbsence.IsEmpty() then
                        Error(Text001, FieldCaption("Base Unit of Measure"), EmployeeAbsence.TableCaption());

                HumanResUnitOfMeasure.Get("Base Unit of Measure");
                HumanResUnitOfMeasure.TestField("Qty. per Unit of Measure", 1);
            end;
        }
        field(4; "Automatically Create Resource"; Boolean)
        {
            Caption = 'Automatically Create Resource';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot change %1 because there are %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

