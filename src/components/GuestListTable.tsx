import { Guest } from '../lib/supabase'
import { Button } from './Button'

interface GuestListTableProps {
  guests: Guest[]
  onDelete: (guestId: string) => void
  onRefresh: () => void
}

export const GuestListTable: React.FC<GuestListTableProps> = ({
  guests,
  onDelete,
}) => {
  const getStatusBadge = (status: string) => {
    const badges: Record<string, { bg: string; text: string }> = {
      invited: { bg: 'bg-blue-100', text: 'text-blue-700' },
      accepted: { bg: 'bg-green-100', text: 'text-green-700' },
      declined: { bg: 'bg-red-100', text: 'text-red-700' },
      maybe: { bg: 'bg-yellow-100', text: 'text-yellow-700' },
      pending: { bg: 'bg-gray-100', text: 'text-gray-700' },
    }
    const badge = badges[status] || badges.pending
    return (
      <span className={`px-2 py-1 ${badge.bg} ${badge.text} text-xs rounded capitalize`}>
        {status}
      </span>
    )
  }

  const getSideBadge = (side: string) => {
    const colors = {
      groom: 'bg-blue-100 text-blue-700',
      bride: 'bg-pink-100 text-pink-700',
      both: 'bg-purple-100 text-purple-700',
    }
    return (
      <span className={`px-2 py-1 ${colors[side as keyof typeof colors]} text-xs rounded capitalize`}>
        {side}
      </span>
    )
  }

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Contact
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Side
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Tags
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {guests.map((guest) => (
              <tr key={guest.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <div className="flex-shrink-0 h-10 w-10">
                      <div className="h-10 w-10 rounded-full bg-gradient-to-br from-primary-400 to-secondary-400 flex items-center justify-center text-white font-semibold">
                        {guest.full_name.charAt(0)}
                      </div>
                    </div>
                    <div className="ml-4">
                      <div className="text-sm font-medium text-gray-900">{guest.full_name}</div>
                      {guest.plus_one_allowed && guest.plus_one_name && (
                        <div className="text-xs text-gray-500">+1: {guest.plus_one_name}</div>
                      )}
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">{guest.email || '-'}</div>
                  <div className="text-xs text-gray-500">{guest.phone || '-'}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {getSideBadge(guest.side)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className="text-sm text-gray-900 capitalize">{guest.role}</span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {getStatusBadge(guest.status)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex flex-wrap gap-1">
                    {guest.is_vip && (
                      <span className="px-2 py-0.5 bg-yellow-100 text-yellow-700 text-xs rounded">
                        VIP
                      </span>
                    )}
                    {guest.plus_one_allowed && (
                      <span className="px-2 py-0.5 bg-purple-100 text-purple-700 text-xs rounded">
                        +1
                      </span>
                    )}
                    {guest.under_18 && (
                      <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded">
                        U18
                      </span>
                    )}
                    {guest.can_invite_others && (
                      <span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs rounded">
                        Can Invite
                      </span>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <Button
                    size="sm"
                    variant="secondary"
                    onClick={() => onDelete(guest.id)}
                  >
                    Remove
                  </Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
