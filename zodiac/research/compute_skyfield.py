from pathlib import Path
import sys,json,datetime as dt,hashlib
sys.path.insert(0,str(Path(__file__).resolve().parent/'python'))
import numpy as np,skyfield
from skyfield.api import load_file,Loader,load_constellation_map
root=Path(__file__).resolve().parent
load=Loader(str(root),verbose=False);ts=load.timescale(builtin=True);eph=load('https://ssd.jpl.nasa.gov/ftp/eph/planets/bsp/de421.bsp');earth=eph['earth'];sun=eph['sun'];find=load_constellation_map()
def classify(t):return np.asarray(find(earth.at(t).observe(sun).apparent()))
start=dt.date(2024,12,1);end=dt.date(2031,2,1);dates=[start+dt.timedelta(days=i) for i in range((end-start).days+1)]
times=ts.from_datetimes([dt.datetime.fromisoformat(d.isoformat()+'T12:00:00+00:00') for d in dates]);ids=classify(times)
expected=['Cap','Aqr','Psc','Ari','Tau','Gem','Cnc','Leo','Vir','Lib','Sco','Oph','Sgr'];assert set(ids)==set(expected)
indices=np.flatnonzero(ids[1:]!=ids[:-1])+1;before=ids[indices-1];after=ids[indices];lo=times.tt[indices-1].copy();hi=times.tt[indices].copy()
for _ in range(20):
 mid=(lo+hi)/2;at=classify(ts.tt_jd(mid));assert np.all((at==before)|(at==after));same=at==before;lo=np.where(same,mid,lo);hi=np.where(same,hi,mid)
iso=ts.tt_jd((lo+hi)/2).utc_iso()
transitions=[{'from':str(before[j]),'to':str(after[j]),'timeUTC':str(iso[j]),'dayStart':dates[k].isoformat()} for j,k in enumerate(indices)]
ru={'Cap':'Козерог','Aqr':'Водолей','Psc':'Рыбы','Ari':'Овен','Tau':'Телец','Gem':'Близнецы','Cnc':'Рак','Leo':'Лев','Vir':'Дева','Lib':'Весы','Sco':'Скорпион','Oph':'Змееносец','Sgr':'Стрелец'}
latin={'Cap':'Capricornus','Aqr':'Aquarius','Psc':'Pisces','Ari':'Aries','Tau':'Taurus','Gem':'Gemini','Cnc':'Cancer','Leo':'Leo','Vir':'Virgo','Lib':'Libra','Sco':'Scorpius','Oph':'Ophiuchus','Sgr':'Sagittarius'}
global_map={d.isoformat():str(c) for d,c in zip(dates,ids)};cycles=[]
for year in range(2025,2030):
 first=next(i for i,e in enumerate(transitions) if e['to']=='Cap' and e['dayStart'].startswith(str(year)+'-'));events=transitions[first:first+14];excluded={e['timeUTC'][:10] for e in events};entries=[];daymap={}
 for i,e in enumerate(events[:-1]):
  assert e['to']==expected[i];a=dt.date.fromisoformat(e['dayStart']);b=dt.date.fromisoformat(events[i+1]['dayStart'])-dt.timedelta(days=1)
  row={'id':e['to'],'name':ru[e['to']],'latin':latin[e['to']],'start':a.isoformat(),'end':b.isoformat(),'entryUTC':e['timeUTC'],'exitUTC':events[i+1]['timeUTC'],'entryDate':e['timeUTC'][:10],'exitDate':events[i+1]['timeUTC'][:10],'days':(b-a).days+1}
  for offset in range(row['days']):
   day=(a+dt.timedelta(days=offset)).isoformat();assert day not in daymap;daymap[day]=row['id'];assert global_map[day]==row['id']
  row['eligibleDates']=[day for day,id in daymap.items() if id==row['id'] and day not in excluded]
  assert row['eligibleDates']
  t0=dt.datetime.fromisoformat(row['entryUTC'].replace('Z','+00:00'));t1=dt.datetime.fromisoformat(row['exitUTC'].replace('Z','+00:00'));row['durationDays']=round((t1-t0).total_seconds()/86400,6)
  for day in row['eligibleDates']:
   midnight=dt.datetime.fromisoformat(day+'T00:00:00+00:00');assert t0<midnight and midnight+dt.timedelta(days=1)<t1
  entries.append(row)
 assert len(entries)==13 and set(e['id'] for e in entries)==set(expected)
 cycles.append({'startYear':year,'endYear':year+1,'label':f'Цикл {year}–{year+1}','start':entries[0]['start'],'end':entries[-1]['end'],'days':len(daymap),'entries':entries,'dayMap':daymap,'eligibleDates':[day for day in daymap if day not in excluded],'transitions':events})
sources=[{'title':'IAU — созвездия и официальные границы','url':'https://www.iau.org/IAU/IAU/Astronomy-FAQs/Constellations.aspx'},{'title':'Skyfield — карта границ созвездий и позиции','url':'https://rhodesmill.org/skyfield/api.html#constellations'},{'title':'Skyfield — видимые положения и геоцентрические наблюдения','url':'https://rhodesmill.org/skyfield/positions.html'},{'title':'JPL — эфемериды Солнца и планет','url':'https://ssd.jpl.nasa.gov/planets/eph_export.html'},{'title':'JPL DE421 — исходный файл эфемериды','url':'https://ssd.jpl.nasa.gov/ftp/eph/planets/bsp/de421.bsp'}]
result={'version':2,'dailyTimeUTC':'12:00:00','method':'Geocentric apparent Sun center: Skyfield Earth.at(t).observe(Sun).apparent(), JPL DE421, Skyfield IAU constellation map (B1875).','skyfieldVersion':skyfield.__version__,'ephemeris':'JPL DE421','kernelUrl':sources[-1]['url'],'kernelSHA256':hashlib.sha256((root/'de421.bsp').read_bytes()).hexdigest(),'cycleConvention':'Capricornus January start to next Capricornus January start. entryUTC/exitUTC are calculated Sun-center boundary transitions; the exit date may equal the next row entry date. start/end and dayMap instead classify each date at12:00UTC. Date-only quiz excludes every UTC-calendar day containing a transition, so all eligible dates are unambiguous for the whole UTC day.','constellations':[{'id':i,'name':ru[i],'latin':latin[i]} for i in expected],'cycles':cycles,'sources':sources}
(root/'zodiac-cycles.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));(root/'transitions-skyfield.json').write_text(json.dumps(transitions,ensure_ascii=False,indent=2))
for c in cycles:
 print(c['label'],len(c['dayMap']),'days,',len(c['eligibleDates']),'eligible')
 if c['startYear']==2026:
  for e in c['entries']:print(e['id'],e['entryUTC'],e['exitUTC'])
print('kernel SHA256',result['kernelSHA256'])
