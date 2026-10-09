import 'package:kaundia_app/features/neighbours/domain/neighbour_entities.dart';

/// Raw snake_case payload as served by GET /member/neighbours.
Map<String, dynamic> neighboursJson() => {
      'dag_type': 'rs',
      'plot_limit': 5,
      'properties': [
        {
          'own': {
            'property_id': 12,
            'rs_dag': '830',
            'cs_dag': '412',
            'land_quantity': '5',
            'dag_number': 830,
          },
          'same_dag_owners': [
            {
              'owner_name': 'রহিম উদ্দিন',
              'mobile': '+8801712345678',
              'contact_hidden': false,
              'land_quantity': '3',
              'rs_dag': '830/1',
              'cs_dag': '412',
              'position_label': 'same_dag',
            },
          ],
          'neighbours': [
            {
              'owner_name': 'করিম',
              'mobile': null,
              'contact_hidden': true,
              'land_quantity': null,
              'rs_dag': '831',
              'cs_dag': null,
              'position_label': 'adjacent',
            },
            {
              'owner_name': 'Unknown Pos',
              'mobile': '01812345678',
              'contact_hidden': false,
              'land_quantity': '2.5',
              'rs_dag': '835',
              'cs_dag': '415',
              'position_label': 'far_away',
            },
          ],
        },
        {
          'own': {
            'property_id': 13,
            'rs_dag': null,
            'cs_dag': '500',
            'land_quantity': '4',
            'dag_number': null,
          },
          'same_dag_owners': [],
          'neighbours': [],
        },
      ],
    };

const rahim = NeighbourOwner(
  ownerName: 'রহিম উদ্দিন',
  mobile: '+8801712345678',
  contactHidden: false,
  landQuantity: '3',
  rsDag: '830/1',
  csDag: '412',
  position: NeighbourPosition.sameDag,
);

const karim = NeighbourOwner(
  ownerName: 'করিম',
  mobile: null,
  contactHidden: true,
  landQuantity: null,
  rsDag: '831',
  csDag: null,
  position: NeighbourPosition.adjacent,
);

NeighbourGroup ownGroup(String id, {List<NeighbourOwner> same = const [],
    List<NeighbourOwner> near = const [], int? dagNumber = 830}) =>
    NeighbourGroup(
      own: OwnPlot(
        propertyId: id,
        rsDag: '830',
        csDag: '412',
        landQuantity: '5',
        dagNumber: dagNumber,
      ),
      sameDagOwners: same,
      neighbours: near,
    );

NeighbourDirectory directory(List<NeighbourGroup> groups,
        {DagType type = DagType.rs}) =>
    NeighbourDirectory(dagType: type, plotLimit: 5, properties: groups);
