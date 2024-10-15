namespace Microsoft.Finance.Consolidation;

table 1831 "Bus. Unit In Cons. Process"
{
    Caption = 'Business Unit in Consolidation Process';
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Consolidation Process Id"; Integer)
        {
            TableRelation = "Consolidation Process";
            DataClassification = SystemMetadata;
        }
        field(2; "Business Unit Code"; Code[20])
        {
            TableRelation = "Business Unit";
            DataClassification = CustomerContent;
        }
        field(3; "Default Data Import Method"; Option)
        {
            OptionCaption = 'Database,API';
            OptionMembers = Database,API;
            FieldClass = FlowField;
            CalcFormula = lookup("Business Unit"."Default Data Import Method" where(Code = field("Business Unit Code")));
        }
        field(4; "Status"; Option)
        {
            OptionCaption = 'Not started,Importing data,Consolidating,Finished,Error';
            OptionMembers = NotStarted,ImportingData,Consolidating,Finished,Error;
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Consolidation Process Id", "Business Unit Code")
        {
            Clustered = true;
        }
    }
}