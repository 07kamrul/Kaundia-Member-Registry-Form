/**
 * Neighbour plot owner directory (GET /api/member/neighbours).
 *
 * Mirrors backend/app/schemas/neighbour.py. The server is the privacy
 * whitelist; these mappers still treat the payload as untrusted and never
 * surface a mobile number the owner chose to hide.
 */

export const NEIGHBOUR_DAG_TYPES = ['rs', 'cs'] as const;
export type NeighbourDagType = (typeof NEIGHBOUR_DAG_TYPES)[number];

export const NEIGHBOUR_POSITIONS = ['same_dag', 'adjacent', 'near'] as const;
export type NeighbourPosition = (typeof NEIGHBOUR_POSITIONS)[number];

/** Least specific label - used when the server sends one this client doesn't know. */
const FALLBACK_POSITION: NeighbourPosition = 'near';
const FALLBACK_DAG_TYPE: NeighbourDagType = 'rs';

export interface NeighbourOwnerApiModel {
  owner_name: string;
  mobile: string | null;
  contact_hidden: boolean;
  land_quantity: string | null;
  rs_dag: string | null;
  cs_dag: string | null;
  position_label: string;
}

export interface NeighbourOwnPlotApiModel {
  property_id: number;
  rs_dag: string | null;
  cs_dag: string | null;
  land_quantity: string | null;
  dag_number: number | null;
}

export interface NeighbourGroupApiModel {
  own: NeighbourOwnPlotApiModel;
  same_dag_owners: NeighbourOwnerApiModel[] | null;
  neighbours: NeighbourOwnerApiModel[] | null;
}

export interface NeighbourDirectoryApiModel {
  dag_type: string;
  plot_limit: number;
  properties: NeighbourGroupApiModel[] | null;
}

export interface NeighbourOwner {
  ownerName: string;
  /** Always null when contactHidden is true. */
  mobile: string | null;
  contactHidden: boolean;
  landQuantity: string | null;
  rsDag: string | null;
  csDag: string | null;
  positionLabel: NeighbourPosition;
}

export interface NeighbourOwnPlot {
  propertyId: number;
  rsDag: string | null;
  csDag: string | null;
  landQuantity: string | null;
  /** Null when the property has no usable dag of the requested type. */
  dagNumber: number | null;
}

export interface NeighbourGroup {
  own: NeighbourOwnPlot;
  sameDagOwners: NeighbourOwner[];
  neighbours: NeighbourOwner[];
}

export interface NeighbourDirectory {
  dagType: NeighbourDagType;
  plotLimit: number;
  properties: NeighbourGroup[];
}

function optionalText(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

export function isNeighbourDagType(value: unknown): value is NeighbourDagType {
  return typeof value === 'string' && (NEIGHBOUR_DAG_TYPES as readonly string[]).includes(value);
}

export function toNeighbourPosition(value: unknown): NeighbourPosition {
  return typeof value === 'string' && (NEIGHBOUR_POSITIONS as readonly string[]).includes(value)
    ? (value as NeighbourPosition)
    : FALLBACK_POSITION;
}

export function toNeighbourOwner(api: NeighbourOwnerApiModel): NeighbourOwner {
  const contactHidden = api.contact_hidden === true;
  return {
    ownerName: optionalText(api.owner_name) ?? '',
    mobile: contactHidden ? null : optionalText(api.mobile),
    contactHidden,
    landQuantity: optionalText(api.land_quantity),
    rsDag: optionalText(api.rs_dag),
    csDag: optionalText(api.cs_dag),
    positionLabel: toNeighbourPosition(api.position_label),
  };
}

function toNeighbourGroup(api: NeighbourGroupApiModel): NeighbourGroup {
  const dagNumber = api.own.dag_number;
  return {
    own: {
      propertyId: api.own.property_id,
      rsDag: optionalText(api.own.rs_dag),
      csDag: optionalText(api.own.cs_dag),
      landQuantity: optionalText(api.own.land_quantity),
      dagNumber: typeof dagNumber === 'number' && Number.isFinite(dagNumber) ? dagNumber : null,
    },
    sameDagOwners: (api.same_dag_owners ?? []).map(toNeighbourOwner),
    neighbours: (api.neighbours ?? []).map(toNeighbourOwner),
  };
}

/**
 * @param requested the dag type the client asked for - the fallback when the
 *   echoed dag_type is missing or unknown.
 */
export function toNeighbourDirectory(
  api: NeighbourDirectoryApiModel,
  requested?: NeighbourDagType,
): NeighbourDirectory {
  return {
    dagType: isNeighbourDagType(api.dag_type) ? api.dag_type : (requested ?? FALLBACK_DAG_TYPE),
    plotLimit: Number.isFinite(api.plot_limit) ? api.plot_limit : 0,
    properties: (api.properties ?? []).map(toNeighbourGroup),
  };
}
